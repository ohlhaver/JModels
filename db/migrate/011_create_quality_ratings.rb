class CreateQualityRatings < ActiveRecord::Migration
  
  def self.up
    
    # user/app favorite author subscriptions
    create_table :author_subscriptions do |t|
      t.string  :owner_type, :limit => 20
      t.integer :owner_id, :null => false
      t.integer :author_id
      t.boolean :subscribed
      t.integer :preference, :limit => 1
    end
    add_index :author_subscriptions, [ :owner_type, :owner_id, :preference, :author_id ], :name => 'author_subscriptions_author_pref_idx'
    add_index :author_subscriptions, [ :owner_type, :owner_id, :author_id ], :name => 'author_subsciptions_uniq_idx', :unique => true
    
    # user/app source preferences
    create_table :source_subscriptions do |t|
      t.string  :owner_type, :limit => 20
      t.integer :owner_id, :null => false
      t.integer :source_id
      t.integer :preference, :limit => 1
    end
    add_index :source_subscriptions, [ :owner_type, :owner_id, :preference, :source_id ], :name => 'source_subscriptions_source_pref_idx'
    add_index :source_subscriptions, [ :owner_type, :owner_id, :source_id ], :name => 'source_subscriptions_uniq_idx', :unique => true
    
    create_table( :default_author_ratings ) do |t|
      t.float :rating
    end
    
    create_table( :default_source_ratings ) do |t|
      t.float :rating
    end
    
  end
  
  def self.down
    
    drop_table :author_subscriptions
    drop_table :source_subscriptions
    drop_table :default_author_ratings
    drop_table :default_source_ratings
    
  end
  
end