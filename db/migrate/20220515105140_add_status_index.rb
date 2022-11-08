class AddStatusIndex < ActiveRecord::Migration[7.0]
  def change
    add_index :tinder_accounts, :status
  end
end
