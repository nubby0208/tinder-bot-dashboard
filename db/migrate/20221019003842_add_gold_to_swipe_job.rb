class AddGoldToSwipeJob < ActiveRecord::Migration[7.0]
  def change
    add_column :swipe_jobs, :gold, :boolean, default: true, null: true
  end
end
