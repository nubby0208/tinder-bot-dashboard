class AddNoGoldToTinderAccount < ActiveRecord::Migration[7.0]
  def change
    add_column :tinder_accounts, :no_gold, :boolean, default: false, null: false
  end
end
