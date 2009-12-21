class AddDefaultPreferenceColumn < ActiveRecord::Migration
  
  def self.up
    add_column :authors, :is_opinion, :boolean
    add_column :sources, :default_preference, :integer
    add_column :authors, :default_preference, :integer
    remove_column :author_subscriptions, :category_id
    add_column :topic_subscriptions, :category_id, :integer
  end
  
  def self.down
    remove_column :authors, :is_opinion
    remove_column :sources, :default_preference
    remove_column :authors, :default_preference
    add_column    :author_subscriptions, :category_id, :integer
    remove_column :topic_subscriptions, :category_id
  end
  
end