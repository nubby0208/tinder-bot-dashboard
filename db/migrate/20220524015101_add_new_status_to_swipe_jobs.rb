class AddNewStatusToSwipeJobs < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      ALTER TYPE swipe_job_status ADD VALUE 'ran_out_of_likes';
    SQL
  end
end
