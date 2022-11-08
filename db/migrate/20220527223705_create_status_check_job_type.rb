class CreateStatusCheckJobType < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      ALTER TYPE swipe_job_type ADD VALUE 'status_check';
    SQL
  end
end
