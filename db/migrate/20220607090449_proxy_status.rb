class ProxyStatus < ActiveRecord::Migration[7.0]
  def change
    add_column :tinder_accounts, :proxy_active, :boolean, null: false, default: true
  end
end
