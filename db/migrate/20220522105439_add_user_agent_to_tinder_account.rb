class AddUserAgentToTinderAccount < ActiveRecord::Migration[7.0]
  def change
    add_column :tinder_accounts, :user_agent, :string
    add_column :tinder_accounts, :resolution, :string
    add_column :tinder_accounts, :language, :string
  end
end
