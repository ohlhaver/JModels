class AddBlockAuthorColumn < ActiveRecord::Migration
  def self.up
    add_column :authors, :block, :boolean, :default => 0
    add_column :story_authors, :block, :boolean, :default => 0
    add_column :author_subscriptions, :block, :boolean, :default => 0
  end

  def self.down
    remove_column :authors, :block
    remove_column :story_authors, :block
    remove_column :author_subscriptions, :block
  end
end
