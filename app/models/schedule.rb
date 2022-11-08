class Schedule < ApplicationRecord
  enum job_type: {
    recommended: 'recommended',
    likes: 'likes',
    status_check: 'status_check',
    location_change: 'location_change',
    limit_of_likes: 'limit_of_likes'
  }, _prefix: :job_type

  validates :swipes_per_day_max,
    :swipes_per_day_min,
    # :swipes_per_day_increment,
    # :swipes_per_day_increment_max,
    :start_time,
    :stop_time,
    :split_jobs,
    :user_id,
    :job_type,
    :recommended_percentage,
    :delay,
    :delay_variance,
    presence: true

  validate :accounts_selected, on: :create
  def accounts_selected
    if status_check_tinder_accounts.present?
      if job_type != 'status_check'
        errors.add(:base, 'Status Check must choose status check accounts')
      end
      return
    end

    return if tinder_accounts.blank? ^ one_time_tinder_accounts.blank?
    errors.add(:base, 'Specify only one type of tinder accounts')
  end

  validate :correct_job_types
  def correct_job_types
    # return if job_type
    if job_type == "status_check" && tinder_accounts.present?
      errors.add(:base, 'No status check accounts selected')
    end
  end

  belongs_to :user
  has_many :status_check_tinder_accounts,
    dependent: :nullify,
    foreign_key: :status_check_schedule_id,
    class_name: 'TinderAccount'
  has_many :one_time_tinder_accounts,
    dependent: :nullify,
    foreign_key: :one_time_schedule_id,
    class_name: 'TinderAccount'
  has_many :tinder_accounts, dependent: :nullify
  has_many :swipe_jobs, dependent: :nullify

  scope :reoccurring, -> { joins(:tinder_accounts).distinct }
  scope :active, -> { joins(:tinder_accounts).where(tinder_accounts: { status: ['active', 'out_of_likes'] }).distinct }
  scope :one_time , -> { joins(:one_time_tinder_accounts).distinct }

  after_create :run

  def self.run_all
    active.map(&:run)
  end

  def jobs_created_today
    swipe_jobs.where("created_at > ?", recurring.hours.ago)
  end

  def can_schedule_today?
    return true if Time.zone.now < start_today
    start_today <= Time.zone.now && Time.zone.now <= stop_today
  end

  def start_today
    ct = Time.zone.now
    date1 = start_time.change({year: ct.year, month: ct.month, day: ct.day })
    date2 = date1 + recurring.hours
    return date2 if Time.zone.now > date2
    date1
  end

  def stop_today
    ct = Time.zone.now
    date1 = stop_time.change({year: ct.year, month: ct.month, day: ct.day })
    date2 = date1 - recurring.hours
    return date2 if Time.zone.now < date2
    date1
  end

  def title
    if created_at
      "#{created_at.strftime("%Y.%m.%d")}-#{accounts_count}-#{id}"
    end
  end

  def active_accounts
    accounts.active
  end

  def accounts_count
    count = tinder_accounts.count
    count == 0 ? one_time_tinder_accounts.count : count
  end

  def active_accounts_count
    accounts.active.count
  end

  def accounts
    return status_check_tinder_accounts if job_type_status_check?
    run_once? ? one_time_tinder_accounts : tinder_accounts
  end

  def run_once?
    one_time_tinder_accounts.present?
  end

  def run_status_check
  end

  def run
    return if run_once? && run_at # skip if already run and its run once
    Schedule.transaction do
      job_runs_by_account = SwipeJob.where(schedule_id: id).group(:tinder_account_id).count
      applicable_accounts = job_type_status_check? ? accounts : accounts.active
      puts start_today
      puts stop_today
      puts Time.zone.now

      applicable_accounts.find_each do |account|
        target = rand(swipes_per_day_min..swipes_per_day_max)

        if run_now || job_type_status_check?
          status = "pending"
        else
          next if has_job_for_next_available_session?(account)
          next if account.status == 'limit_of_likes'

          if swipes_per_day_increment > 0
            # how many jobs have been created with this schedule for this account
            increment_sum = job_runs_by_account[account.id].to_i * swipes_per_day_increment
            target = rand(swipes_per_day_min+increment_sum..swipes_per_day_max+increment_sum)
            if swipes_per_day_increment_max > 0 && target > swipes_per_day_increment_max
              target = swipes_per_day_increment_max
            end
          end

          time_range = stop_today - start_today
          time_range = 0 if time_range < 0
          seconds = rand(0..time_range)
          status = "scheduled"
          scheduled_at = start_today + seconds
          puts "===================== schedule job run time ============================"
          scheduled_at += recurring.hours if !can_schedule_today?
        end

        SwipeJob.create!(
          delay: delay,
          delay_variance: delay_variance,
          job_type: job_type,
          recommended_percentage: recommended_percentage,
          status: status,
          scheduled_at: scheduled_at,
          target: target,
          tinder_account_id: account.id,
          user_id: user_id,
          gold: account.gold,
          warm_up: account.warm_up,
          schedule: self,
        )
      end

      update!(run_at: Time.zone.now)
    end
  end

  def current_schedule_start
    Time.zone.now >= stop_today ? start_today + recurring.hours : start_today
  end

  def current_schedule_stop
    Time.zone.now >= stop_today ? stop_today + recurring.hours : stop_today
  end

  def next_available_session
    { start: current_schedule_start, stop: current_schedule_stop }
  end

  def has_job_for_next_available_session?(account)
    last_job = account.swipe_jobs.where.not(scheduled_at: nil).order("id").last
    return false unless last_job
    # puts "current: #{current_schedule_start} #{last_job.scheduled_at}"
    # current_schedule_start <= last_job.scheduled_at
    res = last_job.scheduled_at >= current_schedule_start && last_job.scheduled_at <= current_schedule_stop
    # puts "\n\n#{account.id} res: #{res} now:#{Time.zone.now} last:#{last_job.scheduled_at} next_stop:#{current_schedule_stop} last_start#{start_today}\n\n"
    res
  end
end
