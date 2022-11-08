class AddNoGoldToSwipeJob < ActiveRecord::Migration[7.0]
  def change
    add_column :swipe_jobs, :no_gold, :boolean, default: false, null: false
  end
end
