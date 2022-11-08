class RemoveNoGoldToTinderAccount < ActiveRecord::Migration[7.0]
  def change
    remove_column :tinder_accounts, :no_gold
  end
end
