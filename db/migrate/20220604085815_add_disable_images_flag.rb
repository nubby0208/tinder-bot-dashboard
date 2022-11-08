class AddDisableImagesFlag < ActiveRecord::Migration[7.0]
  def change
    add_column :tinder_accounts, :disable_images, :boolean, null: false, default: false
  end
end
