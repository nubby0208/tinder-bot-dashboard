class CreateMatches < ActiveRecord::Migration[7.0]
  def change
    create_table :matches do |t|
      t.references :tinder_account, foreign_key: true
      t.string :tinder_user_id, null: false, index: true
      t.string :name, null: false
      t.timestamps
    end
    add_index :matches, [:tinder_account_id, :tinder_user_id], unique: true
  end
end
