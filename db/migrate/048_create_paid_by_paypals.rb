class CreatePaidByPaypals < ActiveRecord::Migration
  def self.up
    create_table :paid_by_paypals do |t|
      t.integer :user_id
      t.string  :plan_name
      t.integer :amount
      t.string  :currency
      t.string  :payment_status
      t.string  :payment_type
      t.string  :transaction_id
      t.string  :subscription_status
      t.string  :payer_email
      t.string  :payer_id
      t.string  :item_id
      t.string  :name
      t.timestamp :ends_at
      t.timestamp :starts_at
    end
    add_index :paid_by_paypals, :transaction_id, :unique => true, :name => 'paypal_idx_p'
    add_index :paid_by_paypals, [ :user_id, :transaction_id ], :unique => true, :name => 'paypal_idx_1'
    add_index :paid_by_paypals, [ :user_id, :starts_at, :transaction_id ], :unique => true, :name => 'paypal_idx_2'
    add_index :paid_by_paypals, [ :user_id, :ends_at, :transaction_id ], :unique => true, :name => 'paypal_idx_3'
  end

  def self.down
    drop_table :paid_by_paypals
  end
end
