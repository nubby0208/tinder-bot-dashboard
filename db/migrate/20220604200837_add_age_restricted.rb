class AddAgeRestricted < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      ALTER TYPE tinder_account_status ADD VALUE 'age_restricted';
    SQL
  end
end
