class ProxyInfo < ActiveRecord::Migration[7.0]
  def change
    add_column :tinder_accounts, :proxy_host, :string
    add_column :tinder_accounts, :proxy_mode, :string
    add_column :tinder_accounts, :proxy_port, :integer
    add_column :tinder_accounts, :proxy_username, :string
    add_column :tinder_accounts, :proxy_password, :string
    add_column :tinder_accounts, :proxy_auto_region, :string
    add_column :tinder_accounts, :proxy_tor_region, :string
  end
end
