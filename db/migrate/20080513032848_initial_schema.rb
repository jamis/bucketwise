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
      t.integer :user_id, :null => false
      t.string  :name, :null => false
      t.string  :role
      t.timestamps
    end

    add_index :accounts, %w(subscription_id name), :unique => true

    create_table :buckets do |t|
      t.integer :account_id, :null => false
      t.integer :user_id, :null => false
      t.string  :name, :null => false
      t.string  :role
      t.timestamps
    end

    add_index :buckets, %w(account_id name), :unique => true
    add_index :buckets, %w(account_id updated_at)

    create_table :events do |t|
      t.integer :subscription_id, :null => false
      t.integer :user_id, :null => false
      t.date    :occurred_on, :null => false
      t.string  :actor, :null => false
      t.integer :check_number
      t.timestamps
    end

    add_index :events, %w(subscription_id occurred_on)
    add_index :events, %w(subscription_id actor)
    add_index :events, %w(subscription_id check_number)
    add_index :events, %w(subscription_id created_at)

    create_table :line_items do |t|
      t.integer :event_id, :null => false
      t.integer :account_id, :null => false
      t.integer :bucket_id, :null => false
      t.integer :amount, :null => false # cents
      t.string  :role, :limit => 20
      t.date    :occurred_on, :null => false
    end

    add_index :line_items, :event_id
    add_index :line_items, :account_id
    add_index :line_items, %w(bucket_id occurred_on)

    create_table :account_items do |t|
      t.integer :event_id, :null => false
      t.integer :account_id, :null => false
      t.integer :amount, :null => false # cents
      t.date    :occurred_on, :null => false
    end

    add_index :account_items, :event_id
    add_index :account_items, %w(account_id occurred_on)
  end

  def self.down
    drop_table :subscriptions
    drop_table :users
    drop_table :subscribed_users
    drop_table :accounts
    drop_table :buckets
    drop_table :events
    drop_table :line_items
    drop_table :account_items
  end
end
