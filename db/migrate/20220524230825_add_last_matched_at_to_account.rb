class AddLastMatchedAtToAccount < ActiveRecord::Migration[7.0]
  def change
    add_column :tinder_accounts, :last_matched_at, :datetime
  end
end
