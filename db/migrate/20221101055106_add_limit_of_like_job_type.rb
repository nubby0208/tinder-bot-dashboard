class AddLimitOfLikeJobType < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      ALTER TYPE swipe_job_type ADD VALUE 'limit_of_likes';
    SQL
  end
end
