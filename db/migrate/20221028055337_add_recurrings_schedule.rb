class AddRecurringsSchedule < ActiveRecord::Migration[7.0]
  def change
    add_column :schedules, :recurring, :integer, default: 24, nil: false
end
end
