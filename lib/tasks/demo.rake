namespace :demo do
  desc "Clear the existing demo account, and rebuild"
  task :reset => [:clear, :build]

  desc "Clear the existing demo account"
  task :clear => :environment do
    if !ENV['CONFIRM']
      abort "if you really mean to clear out the demo account, please set the CONFIRM env var"
    end

    user = User.find_by_user_name('bw.demo')
    if user
      Subscription.transaction do
        user.subscriptions.each { |subscription| subscription.clean }
      end
    end
  end

  desc "Rebuild the demo account and associated users"
  task :build => :environment do
    User.transaction do
      user = User.find_by_user_name('bw.demo')
      if !user
        owner = User.create!(:name => "Demo User", :email => "demo@bucketwise.com",
          :user_name => "bw.demo", :password => "demo")
        guest = User.create!(:name => "Guest User", :email => "guest@bucketwise.com",
          :user_name => "bw.guest", :password => "guest")

        subscription = Subscription.create!(:owner => owner)
        subscription.users << owner
        subscription.users << guest
      else
        subscription = user.subscriptions.first
      end

      Populator.for(subscription) do |make|
        make.account("Checking", 'checking', 1_400_00, 45.days.ago)
        make.account("Mastercard", 'credit-card', -500_00, 45.days.ago, 5000_00)
        make.account("Savings", 'other', 750_00, 45.days.ago)

        # ---------------------------------------------------
        # initial budget
        # ---------------------------------------------------

        make.post(45.days.ago, "Bucket reallocation").
          reallocate("Checking", :from, "General",
            "Groceries"     =>  35_00,
            "Household"     =>  25_00,
            "Entertainment" =>  12_50,
            "Dining"        =>  17_50,
            "Auto Fuel"     =>  20_00,
            "Utilities"     => 240_00,
            "Rent"          => 500_00,
            "r:aside"       => 500_00)

        make.post(45.days.ago, "Bucket reallocation").
          reallocate("Savings", :from, "General", "Short Term" =>  750_00)

        # ---------------------------------------------------
        # paychecks
        # ---------------------------------------------------

        paycheck = make.post(40.days.ago, "Paycheck").
          deposit("Checking",
            "Groceries"        =>  75_00,
            "Household"        =>  50_00,
            "Entertainment"    =>  25_00,
            "Dining"           =>  40_00,
            "Gifts Given"      =>  20_00,
            "Auto Fuel"        =>  40_00,
            "Auto Maintenance" =>  30_00,
            "Auto Insurance"   =>  70_00,
            "Utilities"        => 150_00,
            "Rent"             => 500_00,
            "Books"            =>  30_00,
            "Savings"          => 120_00,
            "General"          =>  50_00)

        make.post(25.days.ago, "Paycheck").copy(paycheck)
        make.post(10.days.ago, "Paycheck").copy(paycheck)

        # ---------------------------------------------------
        # payments
        # ---------------------------------------------------

        water = make.post(42.days.ago, "City water", 80_00).
          source("Checking", "Utilities").check(1001)
        electricity = make.post(42.days.ago, "City power", 80_00).
          source("Checking", "Utilities").check(1002)
        gas = make.post(42.days.ago, "City gas", 80_00).
          source("Checking", "Utilities").check(1003)
        telephone = make.post(38.days.ago, "Telephone", 60_00).
          source("Checking", "Utilities")

        make.post(12.days.ago, "City water").copy(water).check(1006)
        make.post(12.days.ago, "City power").copy(electricity).check(1007)
        make.post(12.days.ago, "City gas").copy(gas).check(1008)
        make.post(8.days.ago, "Telephone").copy(telephone)

        make.post(37.days.ago, "Rent", 1000_00).source("Checking", "Rent").check(1004)
        make.post(7.days.ago, "Rent", 1000_00).source("Checking", "Rent").check(1009)

        # ---------------------------------------------------
        # other stuff
        # ---------------------------------------------------

        make.post(43.days.ago, "Chevron", 17_83).
          source("Mastercard", "General").repay("Checking", "Auto Fuel")
        make.post(37.days.ago, "Chevron", 15_45).
          source("Mastercard", "General").repay("Checking", "Auto Fuel")
        make.post(30.days.ago, "Chevron", 16_08).
          source("Mastercard", "General").repay("Checking", "Auto Fuel")
        make.post(24.days.ago, "Chevron", 18_14).
          source("Mastercard", "General").repay("Checking", "Auto Fuel")
        make.post(21.days.ago, "Shell", 12_97).
          source("Mastercard", "General").repay("Checking", "Auto Fuel").
          tag("travel")
        make.post(16.days.ago, "Chevron", 10_00).
          source("Mastercard", "General").repay("Checking", "Auto Fuel")
        make.post(10.days.ago, "Chevron", 17_76).
          source("Mastercard", "General").repay("Checking", "Auto Fuel")
        make.post(5.days.ago, "Chevron", 14_11).
          source("Mastercard", "General").repay("Checking", "Auto Fuel")

        make.post(44.days.ago, "Albertsons", 30_18).
          source("Checking", "Groceries").
          tag("milk" => 6_42, "tax:sales" => 1_71)
        make.post(39.days.ago, "Albertsons").
          source("Checking", "Groceries" => 21_91, "Household" => 9_11).
          memo("Got an ice-cream scooper").
          tag("tax:sales" => 1_76)
        make.post(33.days.ago, "Albertsons", 18_85).
          source("Checking", "Groceries").
          memo("Some stuff for the party tonight").
          tag("tax:sales" => 1_07, "milk" => 6_81)
        make.post(26.days.ago, "Albertsons").
          source("Checking", "Groceries" => 26_25, "Entertainment" => 19_95).
          memo("Picked up a DVD on a whim...hope it's good").
          tag("tax:sales" => 2_62)
        make.post(18.days.ago, "Albertsons", 29_40).
          source("Checking", "Groceries").
          memo("Milk is sure getting spendy these days!").
          tag("tax:sales" => 1_66, "milk" => 7_02)
        make.post(11.days.ago, "Albertsons", 40_97).
          source("Checking", "Groceries").
          tag("tax:sales" => 2_32)
        make.post(4.days.ago, "Albertsons", 36_41).
          source("Checking", "Groceries").
          tag("tax:sales" => 2_06)

        netflix = make.post(41.days.ago, "Netflix.com", 18_01).
          source("Mastercard", "General").repay("Checking", "Entertainment")
        make.post(11.days.ago, "Netflix.com").copy(netflix)

        make.post(41.days.ago, "Gandalfo's", 10_12).
          source("Mastercard", "General").repay("Checking", "Dining").
          tag("tax:sales" => 57)
        make.post(37.days.ago, "McDonald's", 17_18).
          source("Mastercard", "General").repay("Checking", "Dining").
          memo("lunch with tarasine").
          tag("tax:sales" => 97)
        make.post(22.days.ago, "Applebee's", 36_00).
          source("Mastercard", "General").repay("Checking", "Dining").
          memo("dinner with tarasine").
          tag("date", "gratuity" => 5_00, "tax:sales" => 1_75)
        make.post(8.days.ago, "Movie theater", 29_18).
          source("Mastercard", "General").repay("Checking", "Entertainment").
          memo("movie with tarasine").
          tag("date")
        make.post(8.days.ago, "Red Robin", 37_50).
          source("Mastercard", "General").repay("Checking", "Dining").
          memo("dinner with tarasine").
          tag("date", "gratuity" => 5_00, "tax:sales" => 1_84)

        make.post(24.days.ago, "Amazon.com", 55_81).
          source("Mastercard", "General").repay("Checking", "Books").
          memo("\"Eye of the World\" on CD").
          tag("online")
        make.post(9.days.ago, "Amazon.com", 24_16).
          source("Mastercard", "General").repay("Checking", "Books").
          tag("online")

        make.post(26.days.ago, "Mastercard", 594_67).
          from("Checking", "Aside").to("Mastercard", "General").
          check(1005)

        make.post(19.days.ago, "Savings transfer", 300_00).
          from("Checking", "Savings").to("Savings", "Short Term")
      end
    end
  end
end

