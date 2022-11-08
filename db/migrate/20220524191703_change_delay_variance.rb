class ChangeDelayVariance < ActiveRecord::Migration[7.0]
  def change
    change_column :swipe_jobs, :recommended_percentage, :numeric

    execute <<-SQL
      update swipe_jobs
      set delay_variance=delay_variance*100
      where delay_variance < 1
    SQL
  end
end
