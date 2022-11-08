class RenameTinderAccPassword < ActiveRecord::Migration[7.0]
  def change
    rename_column :tinder_accounts, :password, :acc_pass
  end
end
