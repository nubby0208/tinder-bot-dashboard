class AddNewJobType < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      CREATE TYPE swipe_job_type AS ENUM ('likes', 'recommended');
    SQL
    add_column :swipe_jobs, :job_type, :swipe_job_type, null: false, default: :likes
  end
end
