namespace :data do
  namespace :subscription do
    desc "Dump all data for a single subscription"
    task :dump => :environment do
      id = ENV['ID'] or abort "please specify the subscription id via the ID env var"
      subscription = Subscription.find(id)

      data = {}

      data[:tags] = subscription.tags.map(&:attributes)
      data[:accounts] = subscription.accounts.map(&:attributes)
      data[:actors] = subscription.actors.map(&:attributes)
      data[:events] = subscription.events.map(&:attributes)
      data[:user_subscriptions] = subscription.user_subscriptions.map(&:attributes)

      data[:statements] = subscription.accounts.map(&:statements).flatten.map(&:attributes)
      data[:buckets] = subscription.accounts.map(&:buckets).flatten.map(&:attributes)
      data[:line_items] = subscription.events.map(&:line_items).flatten.map(&:attributes)
      data[:account_items] = subscription.events.map(&:account_items).flatten.map(&:attributes)
      data[:tagged_items] = subscription.events.map(&:tagged_items).flatten.map(&:attributes)

      data[:subscription] = subscription.attributes

      File.open("#{id}.yml", "w") { |f| f.write(data.to_yaml) }
    end

    desc "Restores data for the given subscription file"
    task :load => :environment do
      abort "please confirm (via the CONFIRM env var) that you really want to do this" unless ENV['CONFIRM']

      file = ENV['FILE'] or abort "please specify the dump file via the FILE env var"
      data = YAML.load_file(file)

      insert = Proc.new do |table, record|
        c = ActiveRecord::Base.connection
        columns = record.keys.map { |name| c.quote_column_name(name) }
        values = record.values.map { |value| c.quote(value) }
        c.insert("INSERT INTO #{table} (#{columns.join(",")}) VALUES (#{values.join(",")})")
      end

      Subscription.transaction do
        subscription = Subscription.find_by_id(data[:subscription]['id'])
        subscription.destroy if subscription

        insert.call("subscriptions", data[:subscription])
        %w(tags accounts actors events user_subscriptions statements buckets line_items account_items tagged_items).each do |table|
          Array(data[table.to_sym]).each do |record|
            insert.call(table, record)
          end
        end
      end
    end
  end
end
