class AddScheduledStatusToSwipeJobs < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      ALTER TYPE swipe_job_status ADD VALUE 'scheduled';
    SQL
  end
end
