class AddStatusUpdatedAtToTinderAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :tinder_accounts, :status_updated_at, :datetime
  end
end
