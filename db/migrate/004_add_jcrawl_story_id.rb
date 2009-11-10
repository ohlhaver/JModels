class AddJcrawlStoryId < ActiveRecord::Migration
  
  def self.up
    add_column :stories, :jcrawl_story_id, :string, :length => 24
    add_index :stories, :jcrawl_story_id
  end
  
  def self.down
    remove_column :stories, :jcrawl_story_id
  end
  
end