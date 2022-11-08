class AddEmployeeFlag < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :employer_id, :integer, index: true
    add_foreign_key :users, :users, column: :employer_id
    change_column_null :users, :gologin_api_token, true
  end
end
