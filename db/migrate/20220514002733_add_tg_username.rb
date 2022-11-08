class AddTgUsername < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :tg_username, :string
  end
end
