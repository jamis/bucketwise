namespace :user do
  desc "Create a new user."
  task :create => :environment do
    require 'highline'

    ui = HighLine.new

    name = ui.ask("Name: ")
    email = ui.ask("E-mail: ")
    user_name = ui.ask("User name: ")
    password = ui.ask("Password: ")

    user = User.create(:name => name, :email => email,
      :user_name => user_name, :password => password)

    puts "User `#{user_name}' created: ##{user.id}"
  end

  desc "List users (PAGE env var selects which page of users)"
  task :list => :environment do
    page = ENV['PAGE'].to_i

    users = User.find(:all, :limit => 25, :offset => page * 25, :order => :user_name)

    puts "page ##{page}"
    puts "---------------"

    if users.empty?
      puts "no users found"
    else
      users.each do |user|
        puts "##{user.id}: \"#{user.name}\" <#{user.email}>"
      end
    end
  end

  desc "Report info about particular user (USERNAME env var)."
  task :show => :environment do
    user = User.find_by_user_name(ENV['USERNAME'])

    if user
      puts "##{user.id}: \"#{user.name}\" <#{user.email}>"
    else
      puts "No user with that user name."
    end
  end

  desc "List all subscriptions for the given user (USER_ID env var)"
  task :subscriptions => :environment do
    user = User.find(ENV['USER_ID'])

    if user.subscriptions.empty?
      puts "No subscriptions for `#{user.user_name}' ##{user.id}"
    else
      puts "Subscriptions for `#{user.user_name}' ##{user.id}"
      user.subscriptions.each do |sub|
        puts "##{sub.id}"
      end
    end
  end

  desc "Grant access to a specific subscription id (USER_ID env var, SUBSCRIPTION_ID env var)."
  task :grant => :environment do
    subscription = Subscription.find(ENV['SUBSCRIPTION_ID'])
    user = User.find(ENV['USER_ID'])
    user.subscriptions << subscription
    puts "user `#{user.user_name}' granted access to subscription ##{subscription.id}"
  end

  desc "Revoke access to a specific subscription id (USER_ID env var, SUBSCRIPTION_ID env var)."
  task :revoke => :environment do
    subscription = Subscription.find(ENV['SUBSCRIPTION_ID'])
    user = User.find(ENV['USER_ID'])
    user.subscriptions.delete(subscription)
    puts "user `#{user.user_name}' revoked access to subscription ##{subscription.id}"
  end
end
