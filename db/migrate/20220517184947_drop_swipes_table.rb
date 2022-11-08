class DropSwipesTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :tinder_swipes
  end
end
