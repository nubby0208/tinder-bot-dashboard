class DropGologinColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column :tinder_accounts, :gologin, :boolean
  end
end
