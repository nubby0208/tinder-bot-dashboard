class AddRetryCounterToJobs < ActiveRecord::Migration[7.0]
  def change
    add_column :swipe_jobs, :retries, :integer, null: false, default: 0
  end
end
