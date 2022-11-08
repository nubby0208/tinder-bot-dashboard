class CreateUserPorts < ActiveRecord::Migration[7.0]
  def change
    create_table :ports do |t|
      t.references :user, foreign_key: true, null: false
      t.integer :port, null: false
      t.timestamps
    end

    add_reference :swipe_jobs, :port, foreign_key: true, index: { unique: true }
  end
end
