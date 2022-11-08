class AddProxyToTinderAccount < ActiveRecord::Migration[7.0]
  def change
    add_column :tinder_accounts, :proxy_ip, :string
    add_column :tinder_accounts, :proxy_country, :string
  end
end
