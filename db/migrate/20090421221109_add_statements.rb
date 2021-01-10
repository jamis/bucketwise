class AddStatements < ActiveRecord::Migration[4.2]
  def self.up
    create_table :statements do |t|
      t.integer  :account_id, :null => false
      t.date     :occurred_on, :null => false
      t.integer  :starting_balance
      t.integer  :ending_balance
      t.datetime :balanced_at
      t.timestamps
    end

    add_index :statements, %w(account_id occurred_on)

    add_column :account_items, :statement_id, :integer
    add_index :account_items, %w(statement_id occurred_on)
  end

  def self.down
    drop_table :statements

    remove_index :account_items, %w(statement_id occurred_on)
    remove_column :account_items, :statement_id
  end
end
