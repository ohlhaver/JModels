class AddDeleteAtStoryColumn < ActiveRecord::Migration
  def self.up
    add_column :stories, :delete_at, :timestamp
    add_index :stories, :delete_at
  end

  def self.down
    remove_index :stories, :delete_at
    remove_column :stories, :delete_at
  end
end
