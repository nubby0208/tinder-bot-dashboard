class AddLikedByCountToTinderAccount < ActiveRecord::Migration[7.0]
  def change
    add_column :tinder_accounts, :liked_by_count, :integer
    add_column :tinder_accounts, :liked_by_count_updated_at, :datetime
  end
end
