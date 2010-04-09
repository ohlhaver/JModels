class CreateGatewayMessages < ActiveRecord::Migration
  def self.up
    create_table :gateway_messages do |t|
      t.text :response, :length => 5_000
      t.string :event_type
      t.string :event_id
      t.string :action
      t.string :subscriber_id
      t.boolean :parsed, :default => false
      t.timestamps
    end
    add_index :gateway_messages, :event_id
    add_index :gateway_messages, :subscriber_id
    add_index :gateway_messages, [:event_type, :subscriber_id, :action, :parsed, :event_id], :name => 'gmsg_index'
  end

  def self.down
    drop_table :gateway_messages
  end
end
