class AddProxyCityRegionHostnameOrg < ActiveRecord::Migration[7.0]
  def change
    add_column :tinder_accounts, :proxy_city, :string
    add_column :tinder_accounts, :proxy_region, :string
    add_column :tinder_accounts, :proxy_hostname, :string
    add_column :tinder_accounts, :proxy_org, :string
  end
end
