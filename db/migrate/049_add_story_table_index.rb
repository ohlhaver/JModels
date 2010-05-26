class AddStoryTableIndex < ActiveRecord::Migration
  def self.up
    #add_index :stories, [ :delta, :created_at ], :name => 'stories_sphinx_idx'
    #remove_index :stories, :name => 'stories_created_at_idx'
  end
  
  def self.down
    remove_index :stories, [ :delta, :created_at ], :name => 'stories_sphinx_idx'
    add_index :stories, :created_at, :name => 'stories_created_at_idx'
  end
end
