class DeveloperAppSchemaV0 < ActiveRecord::Migration

  def self.up
    create_table :developers do |t|
      t.string   :name,             :null => false, :default => '', :limit => 50
      t.string   :email,            :null => false, :default => '', :limit => 50
      t.string   :login,            :null => false, :default => '', :limit => 20
      t.string   :crypted_password, :null => false, :default => '', :limit => 40
      t.string   :salt,             :null => false, :default => '', :limit => 40
      t.datetime :created_at
    end
    add_index :developers, [:email], :name => "index_developers_on_email", :unique => true
    add_index :developers, [:login], :name => "index_developers_on_login", :unique => true

    create_table :applications do |t|
      t.string  :name,       :null => false, :default => '', :limit =>  50
      t.string  :secret_key, :null => false, :default => '', :limit =>  50
      t.string  :url,        :null => false, :default => '', :limit =>  1000
      t.boolean :is_active,  :null => false, :default => false
      t.timestamps
    end

    create_table :master_applications,{:id => false} do |t|
      t.integer :application_id,  :null => false, :default => 0
    end
    add_index :master_applications, [:application_id], :name => "index_master_applications_on_application_id"

    create_table :application_developers, {:id => false} do |t|
      t.integer :application_id, :null => false, :default => 0
      t.integer :developer_id,   :null => false, :default => 0
    end
    add_index :application_developers, [:application_id], :name => "index_application_developers_on_application_id"
    add_index :application_developers, [:developer_id], :name => "index_application_developers_on_developer_id"

    create_table :application_source_preferences do |t|
      t.integer :application_id,  :null => false, :default => 0
      t.integer :source_id,  :null => false, :default => 0
      t.integer :preference, :null => false, :default => 0
    end
    add_index :application_source_preferences, [:application_id], :name => "index_source_preferences_application_id"
    add_index :application_source_preferences, [:source_id], :name => "index_source_preferences_source_id"


  end
  def self.down
    drop_table :app_developers
  end
end
