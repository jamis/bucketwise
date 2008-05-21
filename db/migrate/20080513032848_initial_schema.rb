class InitialSchema < ActiveRecord::Migration
  def self.up
    create_table :subscriptions do |t|
      t.integer :owner_id, :null => false
    end

    add_index :subscriptions, :owner_id

    create_table :users do |t|
      t.string  :name, :null => false
      t.string  :email, :null => false
      t.string  :identity_url
      t.timestamps
    end

    add_index :users, :identity_url, :unique => true

    create_table :user_subscriptions do |t|
      t.integer  :subscription_id, :null => false
      t.integer  :user_id, :null => false
      t.datetime :created_at, :null => false
    end

    add_index :user_subscriptions, %w(subscription_id user_id), :unique => true
    add_index :user_subscriptions, :user_id

    create_table :accounts do |t|
      t.integer :subscription_id, :null => false
      t.string  :name, :null => false
      t.string  :role
      t.timestamps
    end

    add_index :accounts, %w(subscription_id name), :unique => true

    create_table :buckets do |t|
      t.integer :account_id, :null => false
      t.string  :name, :null => false
      t.timestamps
    end

    add_index :buckets, %w(account_id name), :unique => true

    create_table :events do |t|
      t.integer :subscription_id, :null => false
      t.integer :user_id, :null => false
      t.date    :occurred_on, :null => false
      t.string  :actor, :null => false
      t.string  :payment_method
      t.integer :check_number
      t.timestamps
    end

    add_index :events, %w(subscription_id occurred_on)
    add_index :events, %w(subscription_id actor)
    add_index :events, %w(subscription_id check_number)
    add_index :events, %w(user_id created_at)

    create_table :account_entries do |t|
      t.integer :event_id, :null => false
      t.integer :account_id, :null => false
      t.integer :amount, :null => false # cents
      t.string  :role, :limit => 20
    end

    add_index :account_entries, :event_id
    add_index :account_entries, :account_id

    create_table :bucket_entries do |t|
      t.integer :event_id, :null => false
      t.integer :bucket_id, :null => false
      t.integer :amount, :null => false # cents
      t.string  :role, :limit => 20
    end

    add_index :bucket_entries, :event_id
    add_index :bucket_entries, :bucket_id
  end

  def self.down
    drop_table :subscriptions
    drop_table :users
    drop_table :subscribed_users
    drop_table :accounts
    drop_table :buckets
    drop_table :events
    drop_table :account_entries
    drop_table :bucket_entries
  end
end
