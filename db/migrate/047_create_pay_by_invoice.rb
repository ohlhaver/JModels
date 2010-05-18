class CreatePayByInvoice < ActiveRecord::Migration
  def self.up
    
    create_table :paid_by_invoices, :id => false do |t|
      t.integer :user_id
      t.integer :plan_id
      t.integer :price
      t.string  :currency, :limit => 4
      t.string  :account_name
      t.string  :address, :limit => 1000
      t.string  :city
      t.string  :country
      t.string  :zip
      t.string  :payment_token
      t.boolean :active, :default => 1
      t.timestamp :next_bill_date
      t.timestamps
    end
    
    add_index :paid_by_invoices, :user_id, :unique => true
    add_index :paid_by_invoices, [ :active, :next_bill_date, :user_id ], :unique => true
    
  end
  
  def self.down
    drop_table :paid_by_invoices
  end
end
