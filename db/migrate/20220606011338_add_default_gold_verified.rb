class AddDefaultGoldVerified < ActiveRecord::Migration[7.0]
  def change
    change_column_default :tinder_accounts, :gold, false
    change_column_default :tinder_accounts, :verified, false
  end
end
