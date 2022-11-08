class CreateAccountSchedule < ActiveRecord::Migration[7.0]
  def change
    # create_table :account_schedules do |t|
    #   t.references :tinder_account, null: false, foreign_key: true
    #   t.references :schedule, null: false, foreign_key: true
    #   t.timestamps
    # end
    # drop_table :ports
    remove_reference :tinder_accounts, :schedule, foreign_key: true, index: { unique: true }
    add_reference :tinder_accounts, :schedule, foreign_key: true
    add_column :schedules, :run_once, :boolean, null: false, default: false
    add_reference :swipe_jobs, :schedule, foreign_key: true

    add_column :schedules, :swipes_per_day_increment_max, :integer, default: 0
    add_column :schedules, :swipes_per_day_increment, :integer, default: 0
    add_column :schedules, :swipes_per_day_min, :integer
    rename_column :schedules, :swipes_per_day, :swipes_per_day_max
    remove_column :schedules, :name, :string
    add_column :schedules, :run_at, :datetime

    add_column :tinder_accounts, :one_time_schedule_id, :integer
    add_foreign_key :tinder_accounts, :schedules, column: :one_time_schedule_id
    add_column :schedules, :run_now, :boolean, default: false, null: false

    # a schedule has many accounts and many jobs
    # an account can have a schedule
    # a job may have a schedule
    # a job's schedule cannot change
    # an account's schedule can change
    # an account can only have one schedule at a time?
    # once a schedule is created, the jobs for that account are created
    # once the jobs for that account are created, the "run_at" time is updated
    # for a run_once job, schedules that have a run_at are never run again
    # reoccuring schedules use the run_at to determine which jobs need to be created
    # the schedule id of a job cannot be altered once the job is created
    # the job scheduler creates the jobs for the schedule
    #
    # after the schedule is RUN it cannot be altered??
    # what if its reoccurring?
  end
end
