class AddUserAccountColumn < ActiveRecord::Migration
  
  def self.up
    add_column :users, :third_party, :string, :limit => 20
  end
  
  def self.down
    remove_column :users, :third_party
  end
  
end