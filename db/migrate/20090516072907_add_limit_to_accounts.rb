class AddLimitToAccounts < ActiveRecord::Migration[4.2]
  def self.up
    add_column :accounts, :limit, :integer
  end

  def self.down
    remove_column :accounts, :limit
  end
end
