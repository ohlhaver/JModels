class CreateAuthorAlias < ActiveRecord::Migration
  
  def self.up
    create_table :author_aliases do |t|
      t.string   :name
      t.integer  :author_id
      t.datetime :created_at
    end
    add_index :author_aliases, :name, :name => 'author_alias_name_idx', :unique => true
    add_index :author_aliases, [ :author_id, :name ], :name => 'author_aliases_idx', :unique => true
  end
  
  def self.down
    drop_table :author_aliases
  end
  
end