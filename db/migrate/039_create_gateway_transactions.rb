class CreateGatewayTransactions < ActiveRecord::Migration
  def self.up
    create_table :gateway_transactions do |t|
      t.integer :billing_record_id
      t.string  :abo_definition_id
      t.string  :actual_bdr_amount
      t.string  :content_id
      t.string  :fee_name
      t.string  :group_id
      t.string  :nation
      t.integer :price
      t.string  :session_id
      t.string  :subscription_id
      t.string  :transaction_id
      t.string  :user_id
      t.string  :user_ip
      t.string  :remote_addr
      t.string  :message
      t.timestamps
    end
  end

  def self.down
    drop_table :gateway_transactions
  end
end
