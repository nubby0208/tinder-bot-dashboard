class AddTryToAccountStatusUpdates < ActiveRecord::Migration[7.0]
  def change
    add_column :account_status_updates, :retry, :integer
  end
end
