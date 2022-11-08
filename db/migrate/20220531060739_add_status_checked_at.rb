class AddStatusCheckedAt < ActiveRecord::Migration[7.0]
  def change
    add_column :tinder_accounts, :status_checked_at, :datetime
  end
end
