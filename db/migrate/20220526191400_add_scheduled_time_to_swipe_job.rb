class AddScheduledTimeToSwipeJob < ActiveRecord::Migration[7.0]
  def change
    add_column :swipe_jobs, :scheduled_at, :datetime
  end
end
