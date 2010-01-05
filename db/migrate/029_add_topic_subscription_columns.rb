class AddTopicSubscriptionColumns < ActiveRecord::Migration
  def self.up
    add_column :topic_subscriptions, :blog,    :boolean
    add_column :topic_subscriptions, :video,   :boolean
    add_column :topic_subscriptions, :opinion, :boolean
    add_column :topic_subscriptions, :subscription_type, :integer
    add_column :topic_subscriptions, :story_search_hash, :string, :limit => 2500
    add_column :topic_subscriptions, :position, :integer
    TopicSubscription.find_each{ |t| t.send(:add_to_list_bottom); t.save }
  end

  def self.down
    remove_column :topic_subscriptions, :blog
    remove_column :topic_subscriptions, :video
    remove_column :topic_subscriptions, :opinion
    remove_column :topic_subscriptions, :subscription_type
    remove_column :topic_subscriptions, :story_search_hash
    remove_column :topic_subscriptions, :position
  end
end
