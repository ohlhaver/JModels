class AddStoryTableIndices < ActiveRecord::Migration
  def self.up
    add_column :stories, :image_path_cache, :string, :limit => 1024
    remove_column :stories, :thumb_exists
    add_column :stories, :thumb_saved, :boolean
    add_index :stories, :created_at, :name => 'stories_created_at_idx'
    add_index :stories, [ :thumb_saved, :created_at ], :name => 'stories_thumb_saved_idx'
  end

  def self.down
    remove_column :stories, :thumb_saved
    add_column :stories, :thumb_exists, :boolean
    remove_column :stories, :image_path_cache
    remove_index :stories, :name => 'stories_created_at_idx'
    remove_index :stories, :name => 'stories_thumb_saved_idx'
  end
end
