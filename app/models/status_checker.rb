class StatusChecker
  MAX_RUNNING_STATUS_CHECKS = 5

  def initialize(account, schedule)
    @account = account
    @schedule = schedule
  end

  def self.run_all
    User.find_each do |u|
      # puts "checking #{u.name} status checks"
      accounts = u.tinder_accounts.find_each do |account|
        if max_status_checks_running?(u)
          # puts "max status checks already running for #{u.name}"
          break
        end
        new(account, nil).run
      end
    end
  end

  def run
    return if running?
    return if job_ran_in_past_h?(4)
    return if @account.status_shadowbanned? && job_ran_in_past_h?(24)
    return if @account.status_profile_deleted?
    return if @account.status_banned?
    return if @account.status_age_restricted?

    job = SwipeJob.create(
      tinder_account: @account,
      job_type: "status_check",
      delay: 5000,
      gold: @account.gold,
      warm_up: @account.warm_up,
      user: @account.user,
      created_by: :scheduler
    )
    puts "create status check! #{job.id}"
  end

  private

  def self.max_status_checks_running?(user)
    running = SwipeJob
      .where(
        job_type: 'status_check',
        status: ['pending', 'running', 'queued'],
        user: user,
      ).count
    # puts "there are #{running} status checks running for #{user.name}"
    running >= MAX_RUNNING_STATUS_CHECKS
  end

  # a status check or any job ran in the past 4 hours?
  def job_ran_in_past_h?(hours)
    @account
      .swipe_jobs
      .where("created_at > ?", hours.hours.ago)
      .where(status: 'completed')
      .any? || @account
        .swipe_jobs
        .where("created_at > ?", 6.hours.ago)
        .where(job_type: 'status_check')
        .any?
  end

  def running?
    @account.swipe_jobs.where(status: ['running', 'pending', 'queued']).any?
  end

  def hit_target?
    l24h_swipes = @account.swipe_jobs.where("created_at > ?", 1.day.ago).sum(:swipes)
    l24h_swipes >= @schedule.swipes_per_day
  end
end
