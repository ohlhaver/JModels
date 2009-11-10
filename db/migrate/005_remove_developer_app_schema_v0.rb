class RemoveDeveloperAppSchemaV0 < ActiveRecord::Migration

  def self.up
    drop_table :developers
    drop_table :applications
    drop_table :master_applications
    drop_table :application_developers
    drop_table :application_source_preferences
    add_column :stories, :delta, :boolean, :default => true, :null => false
  end
  
  def self.down
    raise 'Cannot Rollback'
  end
  
end