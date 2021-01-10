class CacheBalancesOnBucketsAndAccounts < ActiveRecord::Migration[4.2]
  def self.up
    add_column :accounts, :balance, :integer, :null => false, :default => 0
    add_column :buckets, :balance, :integer, :null => false, :default => 0

    Account.find_each do |account|
      balance = account.account_items.sum(:amount)
      account.update_attribute :balance, balance
    end

    Bucket.find_each do |bucket|
      balance = bucket.line_items.sum(:amount)
      bucket.update_attribute :balance, balance
    end
  end

  def self.down
    remove_column :accounts, :balance, :integer
    remove_column :buckets, :balance, :integer
  end
end
