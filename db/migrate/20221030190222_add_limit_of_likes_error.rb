class AddLimitOfLikesError < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      ALTER TYPE tinder_account_status ADD VALUE 'limit_of_likes';
    SQL
  end
end
