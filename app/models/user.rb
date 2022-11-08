class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable#, :omniauthable, :timeoutable,
  has_many :tinder_accounts
  has_many :swipe_jobs, through: :tinder_accounts
  has_many :employees, class_name: 'User', foreign_key: 'employer_id'
  belongs_to :employer, class_name: 'User', optional: true

  scope :users, ->{ where.not(name: ['admin', 'test']).where(employer_id: nil) }
  scope :employees, ->{ where.not(employer_id: nil) }
  SLEEP_TIME = ENV.fetch("SLEEP", 3)
  HOURS = ENV.fetch("HOURS", 2)

  def sync_gologins
    accounts = tinder_accounts.alive.where("gologin_synced_at IS NULL OR gologin_synced_at < ?", HOURS.to_i.hour.ago)
    puts "there are #{accounts.count} to sync for #{name}" if ENV['DEBUG']
    accounts.find_each do |account|
      begin
        last_sync = account.gologin_synced_at
        account.sync_gologin
        since_last = last_sync ? ((Time.zone.now - last_sync) / 60 / 60) : nil
        puts "synced gologin acc #{account.id}, sleep #{SLEEP_TIME} sec last_sync:#{since_last} hours ago" if ENV['DEBUG']
        sleep SLEEP_TIME.to_i
      rescue => e
        puts("failed updating gologin acc:#{id}")
      end
    end
  end

  def sync_delete_gologins
     accounts = tinder_accounts.profile_deleted
      accounts.find_each do |account|
        begin
          last_sync = account.gologin_synced_at
          account.sync_gologin
          since_last = last_sync ? ((Time.zone.now - last_sync) / 60 / 60) : nil
          puts "synced gologin acc #{account.id}, sleep #{SLEEP_TIME} sec last_sync:#{since_last} hours ago" if ENV['DEBUG']
          sleep SLEEP_TIME.to_i
        rescue => e
          puts("failed updating gologin acc:#{id}")
        end
      end
  end

  def sync_new_gologins
    accounts = tinder_accounts.where("gologin_synced_at IS NULL OR gologin_profile_name IS NULL")
    accounts.find_each do |account|
      begin
        last_sync = account.gologin_synced_at
        account.sync_gologin
        since_last = last_sync ? ((Time.zone.now - last_sync) / 60 / 60) : nil
        puts "synced gologin acc #{account.id}, sleep #{SLEEP_TIME} sec last_sync:#{since_last} hours ago" if ENV['DEBUG']
        sleep SLEEP_TIME.to_i
      rescue => e
        puts("failed updating gologin acc:#{id}")
      end
    end
  end

  def employee?
    employer_id?
  end

  def owner_id
    employer_id ? employer_id : id
  end

  def swipes
    tinder_accounts.sum(:total_swipes)
  end

  def accounts
    tinder_accounts.alive.count
  end

  def jobs
    swipe_jobs.count
  end

  def title
    name
  end

  def accounts_last1d
    tinder_accounts.alive.where("created_at > ?", 1.day.ago).count
  end

  def accounts_last7d
    tinder_accounts.alive.where("created_at > ?", 7.day.ago).count
  end

  def accounts_last30d
    tinder_accounts.alive.where("created_at > ?", 30.day.ago).count
  end

  def active
    tinder_accounts.active.count
  end

  def banned
    tinder_accounts.banned.count
  end

  def captcha
    tinder_accounts.captcha.count
  end

  def logged_out
    tinder_accounts.logged_out.count
  end

  def shadowbanned
    tinder_accounts.shadowbanned.count
  end

  def proxy_error
    tinder_accounts.proxy_error.count
  end

  def under_review
    tinder_accounts.under_review.count
  end

  def gologin_request(path)
    require 'net/http'
    require 'uri'
    uri = URI.parse("https://api.gologin.com/#{path}")
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "*/*"
    request["Authorization"] = "Bearer #{self.gologin_api_token}"
    request["Connection"] = "keep-alive"
    req_options = { use_ssl: uri.scheme == "https", }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    JSON.parse(response.body)
  end

  def gologin_profiles
    gologin_request "browser/v2"
  end

  def gologin_all_profiles
    isRun = true
    pageNumber = 1
    allProfiles = []
    while isRun
      path = "browser/v2?page=#{pageNumber}"
      result = gologin_request(path)
      if result["profiles"].length > 0
        ids = result["profiles"].map{|profile| profile["id"]}
        allProfiles.concat(ids)
        pageNumber = pageNumber + 1
      else
        isRun = false
      end
    end
    allProfiles
  end

  def gologin_folders
    # gologin_request("folders").select do |j|
    #   # puts j
    #   j["name"] && j["name"].match(/tinder/i)
    # end
    gologin_request("folders").reduce({}) {|acc, e| acc[e["name"]] = e["associatedProfiles"]; acc }
  end

  def k8s
    K8sUser.new(self)
  end

  def k8s_namespace
    k8s.namespace
  end
end
