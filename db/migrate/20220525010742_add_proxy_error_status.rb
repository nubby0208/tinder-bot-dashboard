class AddProxyErrorStatus < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      ALTER TYPE tinder_account_status ADD VALUE 'proxy_error';
    SQL
  end
end
