class AddStatusCheckSchedules < ActiveRecord::Migration[7.0]
  def change
    add_column :tinder_accounts, :status_check_schedule_id, :integer
    add_foreign_key :tinder_accounts, :schedules, column: :status_check_schedule_id
  end
end
