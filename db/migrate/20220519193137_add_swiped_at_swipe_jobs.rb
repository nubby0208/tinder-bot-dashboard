class AddSwipedAtSwipeJobs < ActiveRecord::Migration[7.0]
  def change
    add_column :swipe_jobs, :swiped_at, :datetime
  end
end
