class SwipeJob < ApplicationRecord
  enum status: {
    pending: 'pending',
    running: 'running',
    completed: 'completed',
    queued: 'queued',
    cancelled: 'cancelled',
    ran_out_of_likes: 'ran_out_of_likes',
    ran_limit_of_likes: 'ran_limit_of_likes',
    failed: 'failed',
    scheduled: 'scheduled',
  }, _prefix: :status

  enum account_job_status_result: TinderAccount.statuses

  enum job_type: {
    recommended: 'recommended',
    likes: 'likes',
    status_check: 'status_check',
    location_change: 'location_change',
    limit_of_likes: 'limit_of_likes'
  }, _prefix: :job_type

  enum repeat_unit: {
    daily: 'daily',
    hourly: 'hourly',
  }, _prefix: :job_type

  validates :tinder_account, presence: true
  validates :target, presence: true
  has_many :account_status_updates
  has_many :runs, dependent: :delete_all
  belongs_to :tinder_account
  belongs_to :schedule, optional: true
  # validate :scheduled_at_after_now
  belongs_to :user
  has_one :owner, through: :tinder_account, foreign_key: :user_id, source: :user, class_name: 'User'
  validates :delay, inclusion: { in: 100..60000, message: 'The delay must be between 100 and 60000 milliseconds' }
  validates :recommended_percentage, inclusion: { in: 1..100, message: 'The recommended swipe percentage must be between 1 to 100' }
  # validates :delay_variance, inclusion: { in: 1..100, message: 'The recommended swipe percentage must be between 1 to 100' }
  has_many :tinder_swipes

  scope :not_status_check, -> { where.not(job_type: 'status_check') }
  scope :status_check, -> { where(job_type: 'status_check') }
  scope :location_change, -> { where(job_type: 'location_change') }
  scope :limit_of_likes, -> { where(job_type: 'limit_of_likes') }
  scope :running, -> { where(status: 'running') }
  scope :failed, -> { not_status_check.where(status: 'failed') }
  scope :failed_checks, -> { status_check.where(status: 'failed') }
  scope :completed, -> { where(status: 'completed') }
  scope :pending, -> { where(status: 'pending') }
  scope :scheduled, -> { where('scheduled_at IS NOT NULL') }
  scope :past24h, -> { where("created_at > ?", 1.day.ago) }
  scope :by_user, ->(user) { where(user: user) }
  scope :not_warm_up, -> { where(warm_up: false) }
  scope :warm_up, -> { where(warm_up: true) }
  scope :no_gold, -> { where(gold: false ) }
  scope :gold, -> { where(gold: true) }
  scope :my_jobs, -> { where('schedule_id IS NULL').where('scheduled_at IS NULL').where.not(job_type: 'status_check')}
  
  validates :tinder_account_id,
            inclusion: { in: ->(i) { [i.tinder_account_id_was] }, message: "can't change account of a swipejob" },
            on: :update

  after_create :set_scheduled_status
  def set_scheduled_status
    if self.scheduled_at
      self.status = "scheduled"
      self.save
    end
  end

  def self.count_swipes_by_day(scope=SwipeJob)
    scope.where("created_at >= ?", 30.days.ago)
      .order('created_at::date')
      .group('created_at::date')
      .sum(:swipes)
  end

  def self.cumsum_swipes_by_day(scope=SwipeJob)
    sum = 0
    count_swipes_by_day(scope).transform_values { |v| sum += v }
  end

  def self.count_by_day(scope=SwipeJob)
    scope.not_status_check.where("created_at >= ?", 15.days.ago)
      .order('created_at::date')
      .group('created_at::date')
      .count
  end

  def self.counts_by_date(user=nil)
    query = """
      select status, array_agg(count) from (
          select d.date, s.status, count(t.status)
          FROM (
              select distinct status from swipe_jobs
              where status in ('completed', 'failed')
              order by status
          ) s
          cross join (
              SELECT t.day::date date
              FROM generate_series(
                  date_trunc('day', now() - INTERVAL '15 day')::timestamp without time zone,
                  date_trunc('day', now())::timestamp without time zone,
                  interval  '1 day'
              ) AS t(day)
          ) d
          left outer join (
              select distinct on (
                  id,
                  date_trunc('day', created_at)
              ) swipe_jobs.id,
              date_trunc('day', created_at) date,
              status
              from swipe_jobs
              where status in ('completed', 'failed')
              and job_type not in ('status_check')
              #{"and user_id = #{user.id}" if user}
              order by date_trunc('day', created_at)
          ) t on d.date = t.date and s.status = t.status
          group by d.date, s.status
          order by d.date
      )t
      group by status
      order by status
      ;
    """
    res = ActiveRecord::Base.connection.execute(query)
    res.values.to_h.transform_values { |v| v.gsub(/{|}/, "").split(",").map(&:to_i) }
  end

  def self.counts_checks_by_date(user=nil)
    query = """
      select status, array_agg(count) from (
          select d.date, s.status, count(t.status)
          FROM (
              select distinct status from swipe_jobs
              where status in ('completed', 'failed')
              order by status
          ) s
          cross join (
              SELECT t.day::date date
              FROM generate_series(
                date_trunc('day', now() - INTERVAL '15 day')::timestamp without time zone,
                date_trunc('day', now())::timestamp without time zone,
                  interval  '1 day'
              ) AS t(day)
          ) d
          left outer join (
              select distinct on (
                  id,
                  date_trunc('day', created_at)
              ) swipe_jobs.id,
              date_trunc('day', created_at) date,
              status
              from swipe_jobs
              where job_type = 'status_check'
              #{"and user_id = #{user.id}" if user}
              order by date_trunc('day', created_at)
          ) t on d.date = t.date and s.status = t.status
          group by d.date, s.status
          order by d.date
      )t
      group by status
      order by status
      ;
    """
    res = ActiveRecord::Base.connection.execute(query)
    res.values.to_h.transform_values { |v| v.gsub(/{|}/, "").split(",").map(&:to_i) }
  end

  def self.datasets(user=nil)
    colors = %w(blue red)
    i= 0
    counts_by_date(user).map do |k,v|
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

  def self.datasets_checks(user=nil)
    colors = %w(blue red)
    i= 0
    counts_checks_by_date(user).map do |k,v|
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

  def self.cumsum_swipes_by_day(scope=SwipeJob)
    sum = 0
    count_swipes_by_day(scope).transform_values { |v| sum += v }
  end

  def title
    id
  end

  def stopped_more_than_one_min_ago?
    (completed_at && status == "completed" && (Time.zone.now - completed_at) > 60) ||
      (failed_at && status == "failed" && (Time.zone.now - failed_at) > 60) ||
        (failed_at && status == "cancelled" && (Time.zone.now - failed_at) > 60)
  end

  def run_scheduled_now
    return unless status == "scheduled"

    SwipeJob.create(
      tinder_account: tinder_account,
      target: target,
      user: user,
      gold: tinder_account.gold,
      warm_up: tinder_account.warm_up,
      job_type: job_type,
      delay: delay,
      retries: retries,
      recommended_percentage: recommended_percentage,
      delay_variance: delay_variance,
    )
  end

  # def scheduled_at_after_now
  #   return unless self.scheduled_at
  #   unless self.scheduled_at > Time.now.utc
  #     errors.add(:scheduled_at, "must be after current time")
  #   end
  # end

  delegate :last_matched_at, to: :tinder_account

  def self.running_for_user(user)
    joins(:tinder_account).where(tinder_account: { user: user }, status: 'running')
  end

  def self.queued_for_user(user)
    joins(:tinder_account).where(tinder_account: { user: user }, status: 'queued')
  end

  # validates(
  #   :tinder_account_id,
  #   uniqueness: {
  #     conditions: -> { where(status: ['pending', 'running']) } ,
  #     message: 'swipe job already queued/running'
  #   }
  # )

  # validate :tinder_account_status_active
  # def tinder_account_status_active
  #   if !(tinder_account.status == TinderAccount.statuses['active'])
  #     errors.add(:tinder_account_status, " for #{tinder_account.gologin_profile_name} is #{tinder_account.status}")
  #   end
  #   # if !tinder_account.gologin_profile_id
  #   #   errors.add(:tinder_account_gologin_profile_id, "is missing")
  #   # end
  # end

  def k8s
    K8sJob.new(self)
  end

  def tinder_account_status
    tinder_account.status
  end

  def err_image
    if File.exists?(Rails.root.join('public', "screenshots/#{id}/errscreenshot.png")) #&& status == "failed"
      "/screenshots/#{id}/errscreenshot.png"
    else
      ""
    end
  end

  def krecreate
    cancel
    kreate
  end

  def kreate
    k8s.create
  end

  def cancel!
    if status == "scheduled"
      self.delete
    elsif !["pending", "running"].include?(status)
      errors.add(:status, "cannot cancel #{status} job")
    else
      self.update!( status: 'cancelled', failed_at: Time.zone.now)
    end
  end

  def image
    if File.exists?(Rails.root.join('public', "screenshots/#{id}/screenshot.png")) #&& status == "failed"
      "/screenshots/#{id}/screenshot.png"
    else
      ""
    end
  end

  def logs
    if File.exists?(Rails.root.join("../logs/#{id}.log"))
      File.readlines(Rails.root.join("../logs/#{id}.log"))
    else
      ["no logs present"]
    end
  end

  def video_links
    if Rails.env.development?
      path = Rails.root.join("../videos/#{id}/*")
    else
      path = "/var/www/videos/#{id}/*"
    end
    Dir.glob(path).reduce({}) do |acc,e|
      name = File.basename(e)
      acc[name] = "#{ENV['HOSTNAME']}/1c8e195cc47872f46bbe9151aa03faa714563c5b23fcf5f13ebc593cb2aeb042/videos/#{id}/#{name}"
      acc
    end
  end

  def video_link
    return unless stopped_more_than_one_min_ago?
    if !Rails.env.development?
      path = "/var/www/videos/#{id}/*"
    else
      path = Rails.root.join("../videos/#{id}/*")
    end
    last_path = Dir.glob(path).max_by {|f| File.mtime(f)}

    # require 'pry'; binding.pry
    if last_path.nil? || !File.exists?(last_path)
      errors.add(:video_link,  "does not exist #{last_path}")
      nil
    else
      "#{ENV['HOSTNAME']}/1c8e195cc47872f46bbe9151aa03faa714563c5b23fcf5f13ebc593cb2aeb042/videos/#{id}/#{File.basename(last_path)}"
    end
  end

  def retry!
    if status == "scheduled"
      errors.add(:retries, "cannot retry scheduled job")
      false
    elsif status == "running"
      errors.add(:retries, "cannot retry running job")
      false
    # elsif swipes < target
    else
      update!(status: 'pending', retries: retries + 1)
    end
  end

  def view_href
    return nil unless port
    "http://localhost:#{port.port}/vnc_auto.html"
  end
end
