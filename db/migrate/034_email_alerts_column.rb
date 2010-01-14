class EmailAlertsColumn < ActiveRecord::Migration
  
  def self.up
    add_column :users, :last_author_email_alert_at, :timestamp
    add_column :users, :last_topic_email_alert_at, :timestamp
    add_column :topic_subscriptions, :email_alert, :boolean, :default => false
    add_index :topic_subscriptions, ["owner_type", "owner_id", "email_alert", "position"], :name => 'owner_topics_with_email_alerts'
    add_index :topic_subscriptions, ["owner_type", "owner_id", "home_group", "position"], :name => 'owner_topics_with_home_groups'
  end
  
  def self.down
    remove_index :topic_subscriptions, :name => 'owner_topics_with_email_alerts'
    remove_index :topic_subscriptions, :name => 'owner_topics_with_home_groups'
    remove_column :users, :last_author_email_alert_at
    remove_column :users, :last_topic_email_alert_at
    remove_column :topic_subscriptions, :email_alert
  end
  
end