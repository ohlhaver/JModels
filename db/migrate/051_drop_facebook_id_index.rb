class DropFacebookIdIndex < ActiveRecord::Migration
  def self.up
    remove_index :users, :facebook_uid
    add_index :users, :facebook_uid
  end

  def self.down
  end
end
