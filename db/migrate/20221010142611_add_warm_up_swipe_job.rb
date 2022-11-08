class AddWarmUpSwipeJob < ActiveRecord::Migration[7.0]
  def change
    add_column :swipe_jobs, :warm_up, :boolean, default: false, null: false
  end
end
