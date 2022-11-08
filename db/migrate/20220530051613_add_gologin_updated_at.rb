class AddGologinUpdatedAt < ActiveRecord::Migration[7.0]
  def change
    add_column :tinder_accounts, :gologin_synced_at, :datetime
  end
end
