class AddMemoFieldToEvent < ActiveRecord::Migration[4.2]
  def self.up
    add_column :events, :memo, :text
  end

  def self.down
    remove_column :events, :memo
  end
end
