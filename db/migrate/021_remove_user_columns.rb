class RemoveUserColumns < ActiveRecord::Migration
  
  def self.up
    remove_column :users, :account_activated
    remove_column :users, :account_activation_key
  end
  
  def self.down
    add_column :users, :account_activated, :boolean
    add_column :users, :account_activation_key, :string, :limit => 20
  end
  
end