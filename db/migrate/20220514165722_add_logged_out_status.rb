class AddLoggedOutStatus < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      ALTER TYPE tinder_account_status ADD VALUE 'logged_out';
    SQL
  end
end
