class NormalizeActors < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :events, :actor, :actor_name
    add_column :events, :actor_id, :integer
    add_index :events, :actor_id

    create_table :actors do |t|
      t.integer :subscription_id, :null => false
      t.string  :name, :null => false
      t.string  :sort_name, :null => false
      t.timestamps
    end

    add_index :actors, %w(subscription_id sort_name), :unique => true
    add_index :actors, %w(subscription_id updated_at)

    say_with_time "normalizing all existing event actors" do
      Event.includes(:subscription).each do |event|
        say "normalizing event #{event.id}: #{event.actor_name.inspect}"
        event.update_attribute :actor, event.subscription.actors.normalize(event.actor_name)
      end
    end
  end

  def self.down
    drop_table :actors

    remove_index :events, :actor_id
    remove_column :events, :actor_id
    rename_column :events, :actor_name, :actor
  end
end
