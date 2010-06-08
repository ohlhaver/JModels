class CreateAuthorBlacklists < ActiveRecord::Migration
  def self.up
    create_table :author_blacklists do |t|
      t.string :keyword
    end
    create_table :auto_blacklisted, :id => false do |t|
      t.integer :author_id
    end
    add_index :auto_blacklisted, :author_id, :unique => true
    add_index :author_blacklists, :keyword, :unique => true
    add_column :authors, :auto_blacklisted, :boolean, :default => '0'
    add_index :authors, :auto_blacklisted
  end

  def self.down
    remove_index :authors, :auto_blacklisted
    remove_column :authors, :auto_blacklisted
    drop_table :author_blacklists
    drop_table :auto_blacklisted
  end
end
