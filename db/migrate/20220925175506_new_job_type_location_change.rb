class NewJobTypeLocationChange < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      ALTER TYPE swipe_job_type ADD VALUE 'location_change';
    SQL
  end
end
