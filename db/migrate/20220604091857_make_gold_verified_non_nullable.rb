class MakeGoldVerifiedNonNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :tinder_accounts, :gold, false, false
    change_column_null :tinder_accounts, :verified, false, false
  end
end
