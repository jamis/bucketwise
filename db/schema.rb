# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2009_05_16_072907) do

  create_table "account_items", force: :cascade do |t|
    t.integer "event_id", null: false
    t.integer "account_id", null: false
    t.integer "amount", null: false
    t.date "occurred_on", null: false
    t.integer "statement_id"
    t.index ["account_id", "occurred_on"], name: "index_account_items_on_account_id_and_occurred_on"
    t.index ["event_id"], name: "index_account_items_on_event_id"
    t.index ["statement_id", "occurred_on"], name: "index_account_items_on_statement_id_and_occurred_on"
  end

  create_table "accounts", force: :cascade do |t|
    t.integer "subscription_id", null: false
    t.integer "user_id", null: false
    t.string "name", null: false
    t.string "role"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "balance", default: 0, null: false
    t.integer "limit"
    t.index ["subscription_id", "name"], name: "index_accounts_on_subscription_id_and_name", unique: true
  end

  create_table "actors", force: :cascade do |t|
    t.integer "subscription_id", null: false
    t.string "name", null: false
    t.string "sort_name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["subscription_id", "sort_name"], name: "index_actors_on_subscription_id_and_sort_name", unique: true
    t.index ["subscription_id", "updated_at"], name: "index_actors_on_subscription_id_and_updated_at"
  end

  create_table "buckets", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "user_id", null: false
    t.string "name", null: false
    t.string "role"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "balance", default: 0, null: false
    t.index ["account_id", "name"], name: "index_buckets_on_account_id_and_name", unique: true
    t.index ["account_id", "updated_at"], name: "index_buckets_on_account_id_and_updated_at"
  end

  create_table "events", force: :cascade do |t|
    t.integer "subscription_id", null: false
    t.integer "user_id", null: false
    t.date "occurred_on", null: false
    t.string "actor_name", null: false
    t.integer "check_number"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "memo"
    t.integer "actor_id"
    t.index ["actor_id"], name: "index_events_on_actor_id"
    t.index ["subscription_id", "actor_name"], name: "index_events_on_subscription_id_and_actor_name"
    t.index ["subscription_id", "check_number"], name: "index_events_on_subscription_id_and_check_number"
    t.index ["subscription_id", "created_at"], name: "index_events_on_subscription_id_and_created_at"
    t.index ["subscription_id", "occurred_on"], name: "index_events_on_subscription_id_and_occurred_on"
  end

  create_table "line_items", force: :cascade do |t|
    t.integer "event_id", null: false
    t.integer "account_id", null: false
    t.integer "bucket_id", null: false
    t.integer "amount", null: false
    t.string "role", limit: 20
    t.date "occurred_on", null: false
    t.index ["account_id"], name: "index_line_items_on_account_id"
    t.index ["bucket_id", "occurred_on"], name: "index_line_items_on_bucket_id_and_occurred_on"
    t.index ["event_id"], name: "index_line_items_on_event_id"
  end

  create_table "statements", force: :cascade do |t|
    t.integer "account_id", null: false
    t.date "occurred_on", null: false
    t.integer "starting_balance"
    t.integer "ending_balance"
    t.datetime "balanced_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["account_id", "occurred_on"], name: "index_statements_on_account_id_and_occurred_on"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "owner_id", null: false
    t.index ["owner_id"], name: "index_subscriptions_on_owner_id"
  end

  create_table "tagged_items", force: :cascade do |t|
    t.integer "event_id", null: false
    t.integer "tag_id", null: false
    t.date "occurred_on", null: false
    t.integer "amount", null: false
    t.index ["event_id"], name: "index_tagged_items_on_event_id"
    t.index ["tag_id", "occurred_on"], name: "index_tagged_items_on_tag_id_and_occurred_on"
  end

  create_table "tags", force: :cascade do |t|
    t.integer "subscription_id", null: false
    t.string "name", null: false
    t.integer "balance", default: 0, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["subscription_id", "balance"], name: "index_tags_on_subscription_id_and_balance"
    t.index ["subscription_id", "name"], name: "index_tags_on_subscription_id_and_name", unique: true
  end

  create_table "user_subscriptions", force: :cascade do |t|
    t.integer "subscription_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.index ["subscription_id", "user_id"], name: "index_user_subscriptions_on_subscription_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_user_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "user_name"
    t.string "password_hash"
    t.string "salt"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_name"], name: "index_users_on_user_name", unique: true
  end

end
