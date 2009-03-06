# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20080513032848) do

  create_table "account_items", :force => true do |t|
    t.integer "event_id",   :null => false
    t.integer "account_id", :null => false
    t.integer "amount",     :null => false
  end

  add_index "account_items", ["account_id"], :name => "index_account_items_on_account_id"
  add_index "account_items", ["event_id"], :name => "index_account_items_on_event_id"

  create_table "accounts", :force => true do |t|
    t.integer  "subscription_id", :null => false
    t.string   "name",            :null => false
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "accounts", ["subscription_id", "name"], :name => "index_accounts_on_subscription_id_and_name", :unique => true

  create_table "buckets", :force => true do |t|
    t.integer  "account_id", :null => false
    t.string   "name",       :null => false
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "buckets", ["account_id", "name"], :name => "index_buckets_on_account_id_and_name", :unique => true

  create_table "events", :force => true do |t|
    t.integer  "subscription_id", :null => false
    t.integer  "user_id",         :null => false
    t.date     "occurred_on",     :null => false
    t.string   "actor",           :null => false
    t.integer  "check_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "events", ["user_id", "created_at"], :name => "index_events_on_user_id_and_created_at"
  add_index "events", ["subscription_id", "check_number"], :name => "index_events_on_subscription_id_and_check_number"
  add_index "events", ["subscription_id", "actor"], :name => "index_events_on_subscription_id_and_actor"
  add_index "events", ["subscription_id", "occurred_on"], :name => "index_events_on_subscription_id_and_occurred_on"

  create_table "line_items", :force => true do |t|
    t.integer "event_id",                 :null => false
    t.integer "account_id",               :null => false
    t.integer "bucket_id",                :null => false
    t.integer "amount",                   :null => false
    t.string  "role",       :limit => 20
  end

  add_index "line_items", ["bucket_id"], :name => "index_line_items_on_bucket_id"
  add_index "line_items", ["account_id"], :name => "index_line_items_on_account_id"
  add_index "line_items", ["event_id"], :name => "index_line_items_on_event_id"

  create_table "subscriptions", :force => true do |t|
    t.integer "owner_id", :null => false
  end

  add_index "subscriptions", ["owner_id"], :name => "index_subscriptions_on_owner_id"

  create_table "user_subscriptions", :force => true do |t|
    t.integer  "subscription_id", :null => false
    t.integer  "user_id",         :null => false
    t.datetime "created_at",      :null => false
  end

  add_index "user_subscriptions", ["user_id"], :name => "index_user_subscriptions_on_user_id"
  add_index "user_subscriptions", ["subscription_id", "user_id"], :name => "index_user_subscriptions_on_subscription_id_and_user_id", :unique => true

  create_table "users", :force => true do |t|
    t.string   "name",         :null => false
    t.string   "email",        :null => false
    t.string   "identity_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["identity_url"], :name => "index_users_on_identity_url", :unique => true

end
