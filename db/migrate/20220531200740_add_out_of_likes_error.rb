class AddOutOfLikesError < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      ALTER TYPE tinder_account_status ADD VALUE 'out_of_likes';
    SQL
  end
end
