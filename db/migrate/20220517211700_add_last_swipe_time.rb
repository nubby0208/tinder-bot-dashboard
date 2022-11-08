class AddLastSwipeTime < ActiveRecord::Migration[7.0]
  def change
    add_column :swipe_jobs, :last_swiped, :datetime
  end
end
