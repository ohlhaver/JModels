class CreateUserPreferences < ActiveRecord::Migration
  
  def self.up
    
    add_column :source_subscriptions, :category_id, :integer
    add_column :author_subscriptions, :category_id, :integer
    
    create_table :preferences do |t|
      t.string  :owner_type, :limit => 8
      t.integer :owner_id, :null => false
      t.integer :video, :limit => 1
      t.integer :opinion, :limit => 1
      t.integer :blog, :limit => 1
      t.integer :default_sort_criteria, :limit => 1
      t.integer :subscription_type, :limit => 1
      t.integer :image, :limit => 1
      t.integer :interface_language_id
      t.integer :default_language_id # homepage cluster group default language
      t.integer :default_time_span, :default => 30.days.to_i, :null => false
      t.integer :per_page, :limit => 2
      t.integer :cluster_preview, :limit => 1 # 1 or 3
      t.integer :author_email, :limit => 1
      t.integer :topic_email, :limit => 1
    end
    add_index :preferences, [ :owner_type, :owner_id ], :unique => true
    add_index :preferences, [ :author_email, :owner_type, :owner_id ], :unique => true
    add_index :preferences, [ :topic_email, :owner_type, :owner_id ], :unique => true
    
    # used for storing the preferences like search result language preferences, homepage cluster group preferences
    create_table :multi_valued_preferences do |t|
      t.string  :owner_type, :limit => 20 
      t.integer :owner_id, :null => false
      t.integer :preference_id, :limit => 1
      t.integer :value
      t.integer :position, :default => 0, :null => false
    end
    add_index :multi_valued_preferences, [ :owner_type, :owner_id, :preference_id, :value ], :unique => true, :name => 'multi_valued_preferences_uniq_idx'
    add_index :multi_valued_preferences, [ :owner_type, :owner_id, :preference_id, :position, :value ], :unique => true, :name => 'multi_valued_preferences_position_idx'
    
    # use for the story reading list
    create_table :story_subscriptions do |t|
      t.string  :owner_type, :limit => 20
      t.integer :owner_id, :null => false
      t.integer :story_id
      t.integer :preference, :limit => 1
    end
    add_index :story_subscriptions, [ :owner_type, :owner_id, :preference, :story_id ], :name => 'story_subscriptions_story_pref_idx'
    add_index :story_subscriptions, [ :owner_type, :owner_id, :story_id ], :unique => true, :name => 'story_subscriptions_uniq_idx'
    
    create_table :topic_subscriptions do |t|
      t.string  :owner_type, :limit => 20
      t.integer :owner_id, :null => false
      t.string  :name, :limit => 255
      t.string  :search_any, :limit => 255
      t.string  :search_all, :limit => 255
      t.string  :search_except, :limit => 255
      t.string  :search_exact_phrase, :limit => 255
      t.integer :region_id
      t.integer :source_id
      t.integer :author_id
      t.integer :time_span
      t.integer :sort_criteria, :limit => 1
    end
    add_index :topic_subscriptions, [ :owner_type, :owner_id, :name ], :unique => true
    
    create_table :cluster_groups do |t|
      t.string  :owner_type, :limit => 20
      t.integer :owner_id, :null => false
      t.string  :name
      t.integer :language_id # These are filters ( definite value either english or german ). Nothing to do with ranking
      t.integer :category_id # These are filters
      t.string  :perspective_type, :limit => 20 # Region or ClusterPerspective
      t.integer :perspective_id # RegionId or ClusterPerspectiveId
      t.boolean :public
    end
    add_index :cluster_groups, [ :owner_type, :owner_id, :name ], :unique => true
    add_index :cluster_groups, [ :perspective_type, :perspective_id ]
    add_index :cluster_groups, :public
    
  end
  
  def self.down
    
    drop_table :cluster_groups
    drop_table :topic_subscriptions
    drop_table :story_subscriptions
    drop_table :multi_valued_preferences
    drop_table :preferences
    remove_column :source_subscriptions, :category_id
    remove_column :author_subscriptions, :category_id
    
  end
  
end