class AddProfileDeletedStatusToAccount < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      ALTER TYPE tinder_account_status ADD VALUE 'profile_deleted';
    SQL
  end
end
