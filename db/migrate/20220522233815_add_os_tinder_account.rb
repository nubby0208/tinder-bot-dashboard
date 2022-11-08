class AddOsTinderAccount < ActiveRecord::Migration[7.0]
  def change
    add_column :tinder_accounts, :os, :string
  end
end
