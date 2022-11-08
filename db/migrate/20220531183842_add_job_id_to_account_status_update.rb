class AddJobIdToAccountStatusUpdate < ActiveRecord::Migration[7.0]
  def change
    add_reference :account_status_updates, :swipe_job, foreign_key: true
    execute "drop function log_account_status_update cascade"
  end
end
