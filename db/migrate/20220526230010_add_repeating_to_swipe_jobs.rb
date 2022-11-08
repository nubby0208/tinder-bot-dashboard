class AddRepeatingToSwipeJobs < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      CREATE TYPE swipe_job_repeat_unit AS ENUM ('daily', 'hourly');
    SQL

    add_column :swipe_jobs, :repeat_n, :integer
    add_column :swipe_jobs, :repeat_unit, :swipe_job_repeat_unit

    execute <<-SQL
      ALTER TABLE swipe_jobs
      ADD CONSTRAINT repeat
      CHECK (
        (repeat_unit IS NULL AND repeat_n IS NULL) OR
        (repeat_unit IS NOT NULL AND repeat_n IS NOT NULL)
      )
    SQL

  end
end
