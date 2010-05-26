class AddUserLimitCountColumn < ActiveRecord::Migration
  def self.up
    add_column :users, :author_count, :integer, :default => 0
    add_column :users, :source_count, :integer, :default => 0
    add_column :users, :topic_count, :integer, :default => 0
    User.find_each do |user|
      user.author_count = user.author_subscriptions.count(:all, :without_account_restriction => true )
      user.source_count = user.source_subscriptions.count(:all, :without_account_restriction => true )
      user.topic_count = user.topic_subscriptions.count(:all, :without_account_restriction => true )
      user.save
    end
  end

  def self.down
    remove_column :users, :author_count
    remove_column :users, :source_count
    remove_column :users, :topic_count
  end
end
