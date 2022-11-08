class AddBeforeStatusToAccountStatusUpdates < ActiveRecord::Migration[7.0]
  def change
    add_column :account_status_updates, :before_status, :tinder_account_status
  end
end
