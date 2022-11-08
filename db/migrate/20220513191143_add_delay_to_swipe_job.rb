class AddDelayToSwipeJob < ActiveRecord::Migration[7.0]
  def change
    add_column :swipe_jobs, :delay, :integer, default: 1000, nil: false
  end
end
