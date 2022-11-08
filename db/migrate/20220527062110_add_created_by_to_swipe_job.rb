class AddCreatedByToSwipeJob < ActiveRecord::Migration[7.0]
  def change
    add_column :swipe_jobs, :created_by, :string
  end
end
