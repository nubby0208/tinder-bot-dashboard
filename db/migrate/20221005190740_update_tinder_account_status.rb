class UpdateTinderAccountStatus < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      ALTER TYPE tinder_account_status ADD VALUE 'warm_up';
    SQL
  end
end
