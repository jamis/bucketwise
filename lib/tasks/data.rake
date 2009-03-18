namespace :data do
  task :wipe => :environment do
    abort "data:wipe may only be invoked in development mode" unless RAILS_ENV == "development"
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    mkdir_p "db/backup"
    mv "db/development.sqlite3", "db/backup/development.sqlite3.#{timestamp}"
  end

  task :populate => :environment do
    require 'highline'

    ui = HighLine.new
    name = ENV['BUCKETS_USER'] || ui.ask("Name: ")
    email = ENV['BUCKETS_EMAIL'] || ui.ask("E-mail: ")
    identity = ENV['BUCKETS_IDENTITY'] || ui.ask("OpenID URL: ")

    populate_database(name, email, identity)
  end

  task :reset => [:wipe, "db:migrate", :populate]
end

def populate_database(name, email, identity)
  User.transaction do
    user = User.create(:name => name, :email => email, :identity_url => identity)

    subscription = Subscription.create(:owner => user)
    user.subscriptions << subscription

    checking = subscription.accounts.create(:name => "Checking", :role => "checking", :author => user)
    mastercard = subscription.accounts.create(:name => "Mastercard", :role => "credit-card", :author => user)
    savings = subscription.accounts.create(:name => "Savings", :role => "savings", :author => user)

    dining = checking.buckets.create(:name => "Dining", :author => user)
    groceries = checking.buckets.create(:name => "Groceries", :author => user)
    entertain = checking.buckets.create(:name => "Entertainment", :author => user)
    fuel = checking.buckets.create(:name => "Auto:Fuel", :author => user)
    books = checking.buckets.create(:name => "Books", :author => user)
    tax = checking.buckets.create(:name => "Tax", :author => user)
    aside = checking.buckets.for_role("aside", user)

    save_goal = savings.buckets.create(:name => "Vacation Goal", :author => user)

    subscription.events.create(:user => user, :occurred_on => 8.days.ago,
      :actor => "Starting balance", :line_items => [
        { :account_id => savings.id, :bucket_id => savings.buckets.default.id, :amount => 2345_67 }
      ])

    subscription.events.create(:user => user, :occurred_on => 7.days.ago,
      :actor => "Paycheck", :line_items => [
        { :account_id => checking.id, :bucket_id => dining.id, :amount => 50_00 },
        { :account_id => checking.id, :bucket_id => groceries.id, :amount => 200_00 },
        { :account_id => checking.id, :bucket_id => entertain.id, :amount => 50_00 },
        { :account_id => checking.id, :bucket_id => fuel.id, :amount => 50_00 },
        { :account_id => checking.id, :bucket_id => books.id, :amount => 100_00 },
        { :account_id => checking.id, :bucket_id => checking.buckets.default.id, :amount => 1000_00 }
      ])

    subscription.events.create(:user => user, :occurred_on => 6.days.ago,
      :actor => "McDonald's", :line_items => [
        { :account_id => checking.id, :bucket_id => dining.id,
          :amount => -18_95, :role => "credit_options" },
        { :account_id => checking.id, :bucket_id => tax.id,
          :amount => -1_14, :role => "credit_options" },
        { :account_id => checking.id, :bucket_id => aside.id,
          :amount => 20_09, :role => "credit_options" },
        { :account_id => mastercard.id, :bucket_id => mastercard.buckets.default.id,
          :amount => -20_09, :role => "payment_source" }
      ])

    subscription.events.create(:user => user, :occurred_on => 5.days.ago,
      :actor => "Albertsons", :line_items => [
        { :account_id => checking.id, :bucket_id => groceries.id,
          :amount => -55_22, :role => "payment_source" },
        { :account_id => checking.id, :bucket_id => tax.id,
          :amount => -3_32, :role => "payment_source" }
      ])

    subscription.events.create(:user => user, :occurred_on => 4.days.ago,
      :actor => "Wells Fargo", :line_items => [
        { :account_id => checking.id, :bucket_id => aside.id,
          :amount => -20_09, :role => "payment_source" },
        { :account_id => mastercard.id, :bucket_id => mastercard.buckets.default.id,
          :amount => 20_09, :role => "payment_source" }
      ])

    subscription.events.create(:user => user, :occurred_on => 3.days.ago,
      :actor => "Savings transfer", :line_items => [
        { :account_id => checking.id, :bucket_id => checking.buckets.default.id, :amount => -1000_00 },
        { :account_id => savings.id, :bucket_id => save_goal.id, :amount => 1000_00 }
      ])
  end
end
