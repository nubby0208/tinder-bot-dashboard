class UpdateDelayVarianceDefault < ActiveRecord::Migration[7.0]
  def change
    change_column_default :swipe_jobs, :delay_variance, 30.0
  end
end
