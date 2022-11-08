class AddDelayVarianceToSwipeJob < ActiveRecord::Migration[7.0]
  def change
    add_column :swipe_jobs, :delay_variance, :decimal, default: 0.3, nil: false
  end
end
