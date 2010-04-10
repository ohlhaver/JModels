class AddUserMigrationFields < ActiveRecord::Migration
  
  def self.up
    add_column :users, :old_password_salt, :string, :length => "40"
  end

  def self.down
    remove_column :users, :old_password_salt
  end

end
