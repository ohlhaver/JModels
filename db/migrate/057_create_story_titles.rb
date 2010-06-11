class CreateStoryTitles < ActiveRecord::Migration
  def self.up
    create_table :story_titles, :id => false do |t|
      t.integer :story_id
      t.integer :source_id
      t.string :title
      t.integer :wip, :limit => 1, :default => 0, :null => false
    end
    add_index :story_titles, [ :wip, :title ], :name => 'index_on_story_titles_wip_1'
    add_index :story_titles, [ :wip, :source_id, :title ], :name => 'index_on_story_titles_wip_2'
    
    add_column :stories, :duplicate_checked, :boolean, :default => 0
    add_index :stories, [ :duplicate_checked, :created_at ], :name => 'index_on_stories_duplicate_checked'
    
    StoryTitle.bootstrap!
  end
  
  def self.down
    remove_index :stories, :name => 'index_on_stories_duplicate_checked'
    remove_column :stories, :duplicate_checked
    drop_table :story_titles
  end
  
end
