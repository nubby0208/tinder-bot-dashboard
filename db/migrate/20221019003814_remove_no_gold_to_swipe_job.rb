class RemoveNoGoldToSwipeJob < ActiveRecord::Migration[7.0]
  def change
    remove_column :swipe_jobs, :no_gold
  end
end
