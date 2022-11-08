class RemoveTypeTinderAccountStatus < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      ALTER TYPE tinder_account_status RENAME VALUE 'warm_up' TO '';
    SQL
  end
end
