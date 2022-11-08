class AddRecPercentage < ActiveRecord::Migration[7.0]
  def change
    add_column :swipe_jobs, :recommended_percentage, :integer, null: false, default: 80
  end
end
