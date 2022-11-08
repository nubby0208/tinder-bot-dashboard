class CreateRuns < ActiveRecord::Migration[7.0]
  def change
    create_table :runs do |t|
      t.references :swipe_job, foreign_key: true, null: false
      t.column :status, :swipe_job_status, null: false, default: :running
      t.integer :swipes, null: false, default: 0
      t.column :result, :tinder_account_status
      t.text :failed_reason
      t.datetime :failed_at
      t.datetime :completed_at
      t.timestamps
    end
  end
end
