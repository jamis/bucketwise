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

    create_table :subscribed_users do |t|
      t.integer  :subscription_id, :null => false
      t.integer  :user_id, :null => false
      t.datetime :created_at, :null => false
    end

    add_index :subscribed_users, %w(subscription_id user_id), :unique => true
    add_index :subscribed_users, :user_id

    create_table :accounts do |t|
      t.integer :subscription_id, :null => false
      t.string  :name, :null => false
      t.timestamps
    end

    add_index :accounts, :name, :unique => true

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

    add_index :events, :occurred_on
    add_index :events, :actor
    add_index :events, :check_number

    create_table :entries do |t|
      t.integer :event_id, :null => false
      t.integer :account_id
      t.integer :bucket_id
      t.integer :amount, :null => false # cents
    end

    add_index :entries, :event_id
    add_index :entries, :account_id
    add_index :entries, :bucket_id
  end

  def self.down
    drop_table :subscriptions
    drop_table :users
    drop_table :subscribed_users
    drop_table :accounts
    drop_table :buckets
    drop_table :events
    drop_table :entries
  end
end
