class DropPorts < ActiveRecord::Migration[7.0]
  def change
    drop_table :ports
  end
end
