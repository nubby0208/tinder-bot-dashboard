class AddJobStatusResult2 < ActiveRecord::Migration[7.0]
  def change
    add_column :swipe_jobs, :account_job_status_result, :tinder_account_status
  end
end
