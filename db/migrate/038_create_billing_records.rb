class CreateBillingRecords < ActiveRecord::Migration
  def self.up
    create_table :billing_records do |t|
      t.integer :user_id
      t.integer :plan_id
      t.integer :amount # in millicents
      t.string  :currency
      t.string  :state
      t.string  :checksum_salt # used in generating checksum
      t.timestamps
    end
  end

  def self.down
    drop_table :billing_records
  end
end
