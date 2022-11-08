class AddColumnsToTinderAccount < ActiveRecord::Migration[7.0]
  def change
    create_table :fan_models do |t|
      t.string :name, null: false
      t.references :user, null: false, index: true, foreign_key: true
      t.timestamps
    end

    create_table :locations do |t|
      t.string :name, unique: true, null: false
      t.timestamps
    end

    change_table :tinder_accounts do |t|
      t.string :number
      t.string :email
      t.string :password
      t.boolean :gold
      t.boolean :gologin
      t.boolean :verified
      t.references :location, foreign_key: true
      t.references :fan_model, foreign_key: true
      t.date :created_date
    end

    add_index :tinder_accounts, [:location_id, :user_id, :fan_model_id], unique: true,  name: :location_user_fan
  end
end
