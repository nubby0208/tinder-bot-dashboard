class AccountStatusUpdate < ActiveRecord::Migration[7.0]
  def change
    create_table :account_status_updates do |t|
      t.column :status, :tinder_account_status, null: false
      t.references :tinder_account, null: false, foreign_key: true
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      # t.timestamps
    end
  end
end

