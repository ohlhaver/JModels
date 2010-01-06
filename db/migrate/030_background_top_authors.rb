class BackgroundTopAuthors < ActiveRecord::Migration
  
  def self.up
    
    create_table :bg_top_authors, :id => false do |t|
      t.integer :author_id, :null => false
      t.integer :subscription_count, :null => false, :default => 0
      t.boolean :active, :null => false, :default => false
    end
    add_index :bg_top_authors, [ :active, :author_id, :subscription_count ], :unique => true, :name => 'bg_top_authors_unique_idx'
    
    create_table :bg_top_author_stories, :id => false do |t|
      t.integer :story_id, :null => false
      t.integer :subscription_count, :null => false, :default => 0
      t.boolean :active, :null => false, :default => false
    end
    add_index :bg_top_author_stories, [ :active, :story_id, :subscription_count ], :unique => true, :name => 'bg_top_author_stories_unique_idx'
    
  end
  
  def self.down
    
    drop_table :bg_top_author_stories
    drop_table :bg_top_authors
    
  end
  
  
end