class CreateUsers < ActiveRecord::Migration
  
  def self.up
    
    create_table :users do |t|
      t.string  :name, :limit => 80, :null => false
      t.string  :email, :limit => 255, :null => false
      t.string  :login, :limit => 40
      t.string  :crypted_password, :limit => 64
      t.string  :password_salt, :limit => 20            # Authlogic::Random.friendly_token
      t.integer :facebook_uid, :limit => 8
      t.boolean :account_activated
      t.string  :account_activation_key, :limit => 20   # Authlogic::Random.friendly_token
      t.string  :perishable_token,    :limit => 20      # Authlogic::Random.friendly_token
      t.string  :persistence_token,   :limit => 128, :null => false  # Authlogic::Random.hex_token
      t.string  :single_access_token, :limit => 20, :null => false   # Grants access but does NOT persist e.g. API. Authlogic::Random.friendly_token
      t.boolean :active
      t.boolean :terms_and_conditions_accepted
      t.timestamps
    end
    
    add_index :users, :login, :unique => true
    add_index :users, :facebook_uid, :unique => true
    add_index :users, :email, :unique => true
    execute( 'alter table users auto_increment = 10000000;' ) if adapter_name.downcase =~ /mysql/ && RAILS_ENV == 'production'
    
    create_table :user_roles do |t|
      t.integer :user_id
      t.boolean :admin
      t.boolean :developer
    end
    
    add_index :user_roles, :user_id, :unique => true
  
  end
  
  def self.down
    drop_table :users
    drop_table :user_roles
  end
  
end