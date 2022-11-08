class AddLikeOfLimitSwipeJobStatus < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      ALTER TYPE swipe_job_status ADD VALUE 'ran_limit_of_likes';
    SQL
  end
end
