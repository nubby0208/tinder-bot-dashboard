class AddWarmUpToTinderAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :tinder_accounts, :warm_up, :boolean, default: false, null: false
  end
end
