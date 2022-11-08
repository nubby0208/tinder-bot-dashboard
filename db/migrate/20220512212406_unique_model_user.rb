class UniqueModelUser < ActiveRecord::Migration[7.0]
  def change
    add_index :fan_models, [:name, :user_id], unique: true
  end
end
