class CreateAccountStatusPoints < ActiveRecord::Migration
  def self.up
    create_table :account_status_points do |t|
      t.timestamp :starts_at
      t.timestamp :ends_at
      t.integer :plan_id
      t.integer :billing_record_id
      t.integer :user_id
      t.timestamps
    end
    add_index :account_status_points, :user_id
    add_index :account_status_points, [ :plan_id, :user_id ]
  end

  def self.down
    drop_table :account_status_points
  end
end
