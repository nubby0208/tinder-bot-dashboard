class CreateSchedules < ActiveRecord::Migration[7.0]
  def change
    create_table :schedules do |t|
      t.string :name, null: false, index: { unique: true }
      # t.text :description, null: false
      t.integer :swipes_per_day
      t.time :start_time
      t.time :stop_time
      t.integer :split_jobs, default: 1
      t.column :job_type, :swipe_job_type, null: false, default: :likes
      t.decimal :recommended_percentage, null: false, default: 80.0
      t.decimal :delay, null: false, default: 1000.0
      t.decimal :delay_variance, null: false, default: 30.0
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    add_reference :tinder_accounts, :schedule, foreign_key: true, index: { unique: true }
  end
end
