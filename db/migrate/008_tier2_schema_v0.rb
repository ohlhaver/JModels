class Tier2SchemaV0 < ActiveRecord::Migration
  
  def self.up
    
    create_table :story_teasers do |t|
      t.integer :story_id
      t.string :body, :limit => 2000
    end
    
    create_table :users do |t|
      t.string  :name, :limit => 80, :null => false
      t.string  :email, :limit => 255, :null => false
      t.string  :login, :limit => 40
      t.string  :crypted_password, :limit => 40
      t.string  :password_salt, :limit => 40
      t.string  :jurnalo_id, :limit => 32, :null => false
      t.integer :facebook_uid, :limit => 8
      t.boolean :account_activated
      t.string  :account_activation_key, :limit => 40
      t.boolean :active
      t.boolean :terms_and_conditions_accepted
      t.timestamps
    end
    
    add_index :users, :jurnalo_id, :unique => true
    add_index :users, :login, :unique => true
    add_index :users, :facebook_uid, :unique => true
    add_index :users, :email, :unique => true
    
    create_table :user_roles do |t|
      t.integer :user_id
      t.boolean :admin
      t.boolean :developer
    end
    
    add_index :user_roles, :user_id, :unique => true
    
    create_table :plans do |t|
      t.string  :name, :limit => 80
      t.decimal :price, :precision => 5, :scale => 2
      t.integer :api_limit
      t.boolean :paid
    end
    
    create_table :apps do |t|
      t.integer :owner_id
      t.integer :plan_id
      t.string  :display_name, :limit => 80, :null => false
      t.string  :name, :limit =>  80, :null => false
      t.string  :address, :limit => 1000, :null => false
      t.string  :url, :limit =>  1000
      t.string  :api_key, :limit => 32, :null => false
      t.string  :secret_key, :limit => 32, :null => false
      t.boolean :app_activated
      t.string  :app_activatation_key, :length => 40
      t.boolean :active
      t.boolean :agreement_accepted
      t.boolean :master
      t.timestamps
    end
    
    add_index :apps, :owner_id
    add_index :apps, :name, :unique => true
    add_index :apps, :api_key, :unique => true
    
    # create_table :credit_cards do |t|
    #   t.integer :owner_id
    #   t.string  :card_holder_name
    #   t.string  :last_four_digits
    #   t.string  :crypted_secure_code, :limit => 20, :null => false
    #   t.string  :crypted_credit_card, :limit => 80, :null => false
    #   t.string  :crypted_expiry_month, :limit => 20
    #   t.string  :crypted_expiry_year, :limit => 20
    #   t.string  :billing_address, :limit => 1000
    # end
    # 
    # create_table :app_credit_cards do |t|
    #   t.integer :credit_card_id
    #   t.integer :app_id
    #   t.boolean :auto_charge
    #   t.boolean :last_transaction_successful
    #   t.timestamp :last_transaction_at
    # end
    # 
    # add_index :app_credit_card, :app_id, :unique => true
    
    #
    # Application Cluster Groups should be public for Application Users
    #
    create_table :app_subscriptions do |t|
      t.integer :app_id
      t.integer :user_id
      t.boolean :terms_and_conditions_accepted
      t.boolean :allow
    end
    
    add_index :app_subscriptions, [ :user_id, :app_id ], :unique => true
    add_index :app_subscriptions, [ :app_id, :user_id ], :unique => true
    
    create_table :preferences do |t|
      t.string  :owner_type, :limit => 8
      t.integer :owner_id, :null => false
      t.integer :video, :limit => 1
      t.integer :opinion, :limit => 1
      t.integer :blog, :limit => 1
      t.integer :sort_criteria, :limit => 1
      t.integer :subscription_type, :limit => 1
      t.integer :image, :limit => 1
      t.integer :interface_language_id
      t.integer :default_language_id # homepage cluster group default language
      t.integer :default_time_span, :default => 30.days, :null => false
      t.integer :per_page, :limit => 2
      t.integer :cluster_preview, :limit => 1 # 1 or 3
      t.integer :author_email
      t.integer :topic_email
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
    add_index :preferences, [ :owner_type, :owner_id, :preference_id, :value ], :unique => true, :name => 'multi_valued_preferences_uniq_idx'
    add_index :preferences, [ :owner_type, :owner_id, :preference_id, :position, :value ], :name => 'multi_valued_preferences_position_idx'
    
    # favorite author subscriptions
    create_table :author_subscriptions do |t|
      t.string  :owner_type, :limit => 20
      t.integer :owner_id, :null => false
      t.integer :author_id
      t.boolean :subscribed
      t.integer :author_preference, :limit => 1
    end
    add_index :author_subscriptions, [ :owner_type, :owner_id, :author_preference, :author_id ], :name => 'author_subscriptions_author_pref_idx'
    add_index :author_subscriptions, [ :owner_type, :owner_id, :author_id ], :name => 'author_subsciptions_uniq_idx', :unique => true
    
    # user/app source preferences | cluster_perspective source membership
    create_table :source_subscriptions do |t|
      t.string  :owner_type, :limit => 20
      t.integer :owner_id, :null => false
      t.integer :source_id
      t.integer :source_preference, :limit => 1
    end
    add_index :source_subscriptions, [ :owner_type, :owner_id, :source_preference, :source_id ], :name => 'source_subscriptions_source_pref_idx'
    add_index :source_subscriptions, [ :owner_type, :owner_id, :source_id ], :name => 'source_subscriptions_uniq_idx', :unique => true
    
    # use for the story reading list
    create_table :story_subscriptions do |t|
      t.string  :owner_type, :limit => 20
      t.integer :owner_id, :null => false
      t.integer :story_id
      t.integer :story_preference, :limit => 1
    end
    add_index :story_subscriptions, [ :owner_type, :owner_id, :story_preference, :story_id ], :name => 'story_subscriptions_story_pref_idx'
    add_index :story_subscriptions, [ :owner_type, :owner_id, :story_id ], :unique => true, :name => 'story_subscriptions_uniq_idx'
    
    create_table :topic_subscriptions do |t|
      t.string  :owner_type, :limit => 20
      t.integer :owner_id, :null => false
      t.string  :topic, :limit => 255
    end
    add_index :topic_subscriptions, [ :owner_type, :owner_id, :topic ], :unique => true
    
    create_table :cluster_perspectives do |t|
      t.string  :name, :null => false
      t.integer :app_id, :null => false
      t.boolean :public
      t.timestamps
    end
    add_index :cluster_perspectives, [ :app_id, :name ], :unique => true
    add_index :cluster_perspectives, [ :public, :app_id, :name ], :unique => true
    
    #
    # Background Job Sessions ( Which Iteration is Running )
    #
    create_table :bj_sessions do |t|
      t.integer  :job_id # 0 for Group, 1 for Cluster, etc.
      t.integer  :position, :default => 0, :null => false
      t.datetime :created_at
    end
    add_index :bj_sessions, [ :job_id, :position ]
    
    #
    # Get the stories from the keywords and insert it into the keywords table
    #
    create_table :keywords do |t|
      t.string :name
      t.string :stem
      t.integer :language_id
    end
    add_index :keywords, [ :language_id, :stem ], :unique => true
    
    #
    # Keyword can be mapped to stories or clusters
    #
    create_table :keyword_subscriptions do |t|
      t.string  :owner_type, :limit => 20
      t.integer :owner_id, :null => false
      t.integer :keyword_id
      t.boolean :first_forty
      t.integer :count, :default => 1, :null => false
    end
    add_index :keyword_subscriptions, [ :owner_type, :owner_id, :keyword_id ], :unique => true, :name => 'keyword_subscriptions_owner_idx'
    add_index :keyword_subscriptions, [ :keyword_id, :owner_type, :owner_id ], :unique => true, :name => 'keyword_subscriptions_kw_idx'
    add_index :keyword_subscriptions, [ :owner_type, :owner_id, :keyword_id, :first_forty ], :unique => true, :name => 'keyword_subscriptions_forty_idx'
    
    #
    # Story Groups
    #
    create_table :groups do |t|
      t.integer :pilot_story_id
      t.integer :category_id
      t.integer :bj_session_id
      t.integer :language_id
      t.integer :category_id
      t.integer :story_count # used internally ( originally weight )
      t.integer :broadness
      t.datetime :created_at
    end
    add_index :groups, [ :bj_session_id, :language_id, :category_id, :broadness ]
    
    #
    # Story Clusters ( Clustering considers stories from Last 24.hours )
    #
    create_table :clusters do |t|
      t.integer  :bj_session_id
      t.integer  :pilot_story_id
      t.integer  :language_id
      t.integer  :category_id
      t.integer  :story_count  # used internally ( originally weight )
      t.integer  :broadness    # number of sources + number_of_stories / 100
      t.integer  :video_count
      t.integer  :blog_count
      t.integer  :opinion_count
      t.string   :top_keywords # 3 keywords
      t.integer  :thumbnail_story_id
      t.boolean  :thumbnail_exists
      t.datetime :created_at
    end
    add_index :clusters, [ :bj_session_id, :language_id, :category_id, :broadness ]
    
    #
    # Cluster Perspective Specific Cluster Ratings
    #
    create_table :cluster_ratings do |t|
      t.integer :cluster_id
      t.string  :perspective_type
      t.integer :perspective_id
      t.integer :broadness
    end
    add_index :cluster_ratings, [ :cluster_id, :perspective_type, :perspective_id ], :unique => true
    add_index :cluster_ratings, [ :perspective_type, :perspective_id, :cluster_id, :broadness ], :unique => true
    
    #
    # Cluster Members
    #
    create_table :cluster_subscriptions do |t|
      t.integer :cluster_id
      t.integer :story_id
      t.float   :score
    end
    add_index :cluster_subscriptions, [ :cluster_id, :story_id ], :unique => true, :name => 'cluster_subscriptions_story_idx'
    add_index :cluster_subscriptions, [ :cluster_id, :score, :story_id ], :unique => true, :name => 'cluster_subscriptions_score_idx'
    add_index :cluster_subscriptions, :story_id
    
    #
    # Story Quality Rating
    #
    create_table :quality_ratings do |t|
      t.string  :owner_type
      t.integer :owner_id
      t.integer :story_id
      t.float   :value
    end
    add_index :story_metrics, [ :story_id, :owner_type, :owner_id ], :name => 'quality_rating_story_owner_idx'
    
    #
    # One table to store Top Authors, Top Stories, Top Author Stories, Top Opinions
    # Populated by Background Process
    #
    create_table :top_stories do |t|
      t.integer :story_id
      t.integer :rank
    end
    add_index :top_stories, :story_id, :unique => true
    add_index :top_stories, [ :story_id, :rank ], :unique => true, :name => 'top_stories_uniq_idx1'
    add_index :top_stories, [ :rank, :story_id ], :unique => true, :name => 'top_stories_uniq_idx2'
    
    #
    # Ranked list of Authors based on number of subscriptions
    # Limit to 50 Authors
    #
    create_table :top_authors do |t|
      t.integer :author_id
      t.integer :rank
    end
    add_index :top_stories, :author_id, :unique => true
    add_index :top_stories, [ :rank, :author_id ], :unique => true, :name => 'top_authors_uniq_idx1'
    add_index :top_stories, [ :author_id, :rank ], :unique => true, :name => 'top_authors_uniq_idx2'
    
    #
    # You specify the cluster_perspective_id or region_id
    # Region is just as cluster_perspective_id. Clustering Source List determines the ranking through broadness value.
    #
    create_table :cluster_groups do |t|
      t.string  :owner_type, :limit => 20
      t.string  :owner_id, :null => false
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
    drop_table :top_authors
    drop_table :top_stories
    drop_table :quality_ratings
    drop_table :story_metrics
    drop_table :cluster_subscriptions
    drop_table :cluster_ratings
    drop_table :clusters
    drop_table :groups
    drop_table :keyword_subscriptions
    drop_table :keywords
    drop_table :bj_sessions
    drop_table :cluster_groups
    drop_table :category_subscriptions
    drop_table :cluster_perspectives
    drop_table :topic_subscriptions
    drop_table :story_subscriptions
    drop_table :source_subscriptions
    drop_table :author_subscriptions
    drop_table :multi_valued_preferences
    drop_table :preferences
    drop_table :app_users
    drop_table :apps
    drop_table :plans
    drop_table :user_roles
    drop_table :users
  end
  
end