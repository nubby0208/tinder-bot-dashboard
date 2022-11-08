class DropRunOnceCol < ActiveRecord::Migration[7.0]
  def change
    remove_column :schedules, :run_once, :boolean
  end
end
