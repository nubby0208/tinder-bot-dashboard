require 'net/http'
require 'uri'

class TinderAccount < ApplicationRecord
  enum status: {
    active: 'active',
    age_restricted: 'age_restricted',
    banned: 'banned',
    captcha_required: 'captcha_required',
    identity_verification: 'identity_verification',
    logged_out: 'logged_out',
    out_of_likes: 'out_of_likes',
    limit_of_likes: 'limit_of_likes',
    profile_deleted: 'profile_deleted',
    proxy_error: 'proxy_error',
    shadowbanned: 'shadowbanned',
    under_review: 'under_review',
    verification_required: 'verification_required',
  }, _prefix: :status

  belongs_to :fan_model, optional: true
  belongs_to :location, optional: true
  has_many :account_status_updates, dependent: :delete_all
  has_many :swipe_jobs, dependent: :destroy
  has_many :matches, dependent: :delete_all
  has_many :runs, through: :swipe_jobs, dependent: :destroy

  before_destroy :cancel_swipe_jobs

  def cancel_swipe_jobs
    swipe_jobs.each(&:cancel!)
  end

  validates :gologin_profile_id, uniqueness: true, presence: true
  validates :location, uniqueness: { scope: [:fan_model] }, allow_blank: true
  # validates :fan_model, presence: true
  validates :status, presence: true

  PHONE_REGEX = /\A\d{8,45}\z/
  validates :number,
    format: { with: PHONE_REGEX, message: "phone number must contain only numbers and be at least 8 digits long" },
    allow_nil: true

  REGEX = /\A[a-z0-9]{24}+\z/
  validates :gologin_profile_id, format: { with: REGEX, message: "gologin must be 24 character 0-9a-z" }

  belongs_to :user
  belongs_to :schedule, optional: true

  scope :alive, -> { where.not(status: 'profile_deleted') }
  scope :active, -> { where(status: ['active', 'out_of_likes', 'limit_of_likes']) }
  scope :banned, -> { where(status: ['banned', 'age_restricted']) }
  scope :captcha, -> { where(status: 'captcha_required') }
  scope :identity, -> { where(status: 'identity_verification') }
  scope :logged_out, -> { where(status: 'logged_out') }
  scope :not_deleted, -> { where.not(status: 'profile_deleted') }
  scope :not_scheduled, -> { where(schedule_id: nil) }
  scope :out_of_likes, -> { where(status: 'out_of_likes') }
  scope :profile_deleted, -> { where(status: 'profile_deleted') }
  scope :proxy_error, -> { alive.where(proxy_active: false) }
  scope :shadowbanned, -> { where(status: 'shadowbanned') }
  scope :scheduled, -> { alive.where.not(schedule_id: nil) }
  scope :under_review, -> { where(status: 'under_review') }
  scope :warm_up, -> { where(warm_up: true) }
  scope :no_gold, -> { where(gold: false, status: ['active', 'out_of_likes', 'banned', 'age_restricted', 'captcha_required', 'identity_verification', 'logged_out', 'shadowbanned', 'under_review']) }
  scope :gold, -> { where(gold: true, status: ['active', 'out_of_likes', 'banned', 'age_restricted', 'captcha_required', 'identity_verification', 'logged_out', 'shadowbanned', 'under_review']) }

  def k8s
    K8sAccount.new(self)
  end

  def previous_status
    account_status_updates.where.not(before_status: 'proxy_error').order("id desc").limit(1).first.before_status
  end

  def title
    return "#{gologin_profile_name} #{status}" if gologin_profile_name
    return "#{id} #{fan_model.name} #{status}" if fan_model
    "#{id} #{status}"
  end

  def check_status!
    running = self.swipe_jobs.where(status: ['pending', 'running', 'queued'])

    if running.any?
      errors.add(:check_status, "account is already running a job #{running.pluck(:id).join(",")}")
    else
      SwipeJob.create(
        tinder_account: self,
        job_type: "status_check",
        user: self.user,
        warm_up: self.warm_up,
        created_by: :user
      )
    end
  end

  def self.counts_by_date
    query = """
      select status, array_agg(count) from (
          select d.date, s.status, count(t.status)
          FROM (
              select distinct status
              from tinder_accounts
              where status not in ('profile_deleted', 'proxy_error', 'logged_out', 'banned')
          ) s
          cross join (
              SELECT t.day::date date
              FROM generate_series(
                  timestamp '2022-05-28',
                  timestamp '2022-06-10',
                  interval  '1 day'
              ) AS t(day)
          ) d
          left outer join (
              select distinct on (
                  tinder_accounts.id,
                  date_trunc('day', asu.created_at)
              ) tinder_accounts.id,
              date_trunc('day', asu.created_at) date,
              asu.status
              from tinder_accounts
              join account_status_updates asu on asu.tinder_account_id = tinder_accounts.id
              where asu.status not in ('profile_deleted', 'proxy_error')
              and user_id = 3
              order by date_trunc('day', asu.created_at)
          ) t on d.date = t.date and s.status = t.status
          group by d.date, s.status
          order by d.date
          -- GROUP BY d.date, s.status
          -- ORDER BY d.date
      )t
      group by status
      ;
    """
    res = ActiveRecord::Base.connection.execute(query)
    res.values.to_h.transform_values { |v| v.gsub(/{|}/, "").split(",").map(&:to_i) }
  end

  def self.datasets
    colors = %w(red blue gray green lightblue blueviolet coral yellow salmon gold khaki)
    i= 0
    counts_by_date.map do |k,v|
      x = {
          label: k,
          backgroundColor: colors[i],
          borderColor: colors[i],
          borderWidth: 1,
          data: v,
      }
      i+= 1
      x
    end
  end

  def self.update_counts(last_hours)
    updated_accounts = joins(:swipe_jobs).where("swipe_jobs.created_at > ?", last_hours.hours.ago).distinct
    puts "updating #{updated_accounts.count} accounts with jobs created in the last #{last_hours} hours"
    updated_accounts.find_each do |ta|
      ta.update_column(:total_swipes, ta.swipe_jobs.sum(:swipes))
    end
  end

  # TinderAccount.where(user_id: 5).map {|t| t.update_gologin_name ; sleep(0.5) }

  def update_gologin_name
    return unless (user.name == "Robert" || user.name == "Robert2" || fan_model.try(:name) == "Nika" || user.name == "Prince")
    return if status == "profile_deleted"

    shortname =
      case status
      when "active"
        "ACTIVE"
      when "age_restricted"
        "AGE"
      when "banned"
        "BANNED"
      when "captcha_required"
        "CAPTCHA"
      when "identity_verification"
        "IDENTITY"
      when "logged_out"
        "LOGGEDOUT"
      when "out_of_likes"
        "ACTIVE"
      when "profile_deleted"
        "DELETED"
      when "proxy_error"
        "PROXY"
      when "shadowbanned"
        "SB"
      when "limit_of_likes"
        "LOL"
      when "under_review"
        "UNDER_REVIEW"
      when "verification_required"
        "VERIFICATION"
      else
        return
      end

    if gologin_profile_name.match /^\s?#{shortname} \//
      puts "skipping #{gologin_profile_name}" if ENV['DEBUG']
      return
    end

    names = gologin_profile_name.split(' / ')
    orig_name = names[names.length() - 1]
    
    new_name = "#{shortname} / #{orig_name}"

    uri = URI.parse("https://api.gologin.com/browser/#{gologin_profile_id}/name")
    request = Net::HTTP::Patch.new(uri)
    request["Accept"] = "*/*"
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{user.gologin_api_token}"
    request.body = JSON.dump({ "name" => new_name, })
    req_options = { use_ssl: uri.scheme == "https", }

    begin
      # puts "updating #{gologin_profile_name} status:#{status}"
      puts "#{orig_name}      *****     #{new_name} "
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      if response.code.to_i == 200
        self.update(gologin_profile_name: new_name)
      end
    rescue
      puts "error syncing profile #{id} #{status}"
    end
  end

  def sync_gologin
    uri = URI.parse("https://api.gologin.com/browser/#{gologin_profile_id}")
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "*/*"
    request["Authorization"] = "Bearer #{user.gologin_api_token}"
    request["Connection"] = "keep-alive"

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    body = JSON.parse(response.body)

    if body["statusCode"] == 404 && body["message"] == "Profile has been deleted"
      self.update!(status: 'profile_deleted') and return if self.id
    end

    before_name = gologin_profile_name
    self.gologin_profile_name = body["name"]

    if ENV['DEBUG']
      if before_name != self.gologin_profile_name
        puts "PROFILE #{id} NAME CHANGED: '#{before_name}' -> '#{self.gologin_profile_name}'"
      elsif self.gologin_profile_name.nil?
        puts "PROFILE #{id} NAME IS NULL???"
      else
        puts "PROFILE #{id} SYNCED"
      end
    end

    self.os = body["os"]
    if body["navigator"]
      self.user_agent = body["navigator"]["userAgent"]
      self.resolution = body["navigator"]["resolution"]
      self.language = body["navigator"]["language"]
    end

    proxy = body['proxy']
    if proxy
      self.proxy_mode = proxy['mode']
      self.proxy_host = proxy['host']
      self.proxy_port = proxy['port']
      self.proxy_username = proxy['username']
      self.proxy_password = proxy['password']
      self.proxy_auto_region = proxy['autoProxyRegion']
      self.proxy_tor_region = proxy['torProxyRegion']
    end
    self.gologin_synced_at = Time.zone.now
    self.touch unless self.new_record?
    self.save(validate: false)

    if self.gologin_profile_name != nil
      begin
        update_gologin_name
      rescue => e
        puts e
        puts "ERROR UPDATING GOLOGIN NAME FOR ROBERT"
      end
    end
  end

  def update_proxy_information
    s = Geocoder.search(proxy_ip).try(:first)
    return unless s.try(:city)
    puts "updating proxy" if ENV['DEBUG']
    self.proxy_city =  s.try(:city)
    self.proxy_region = s.region
    self.proxy_org = s.data["org"]
  end

  def self.update_accounts(user)
    user.gologin_profiles.each do |k,v|
      v.each do |e|
        query = where(gologin_profile_id: e)
        name = sync_gologin(e)
        # require 'pry'; binding.pry

        begin
          if query.exists?
            record = query.first
            record.update(
              gologin_folder: k,
              gologin_profile_name: name,
            )
          else
            create!(
              gologin_folder: k,
              gologin_profile_id: e,
              gologin_profile_name: name,
              user: user,
            )
          end
        rescue
          next
        end
      end
    end
  end
end
