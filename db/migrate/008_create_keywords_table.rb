
class CreateKeywordsTable < ActiveRecord::Migration
  
  def self.up
    
    add_column :story_metrics, :keyword_exists, :boolean
    
    #
    # Get the stories from the keywords and insert it into the keywords table
    #
    create_table :keywords do |t|
      t.string  :name # stemmed word
      t.integer :language_id
    end
    add_index :keywords, [ :language_id, :name ], :unique => true
    
    #
    # Keyword can be mapped to stories or clusters
    #
    create_table :keyword_subscriptions do |t|
      t.integer :story_id
      t.integer :keyword_id
      t.integer :frequency
      t.integer :excerpt_frequency
    end
    add_index :keyword_subscriptions, [ :story_id, :keyword_id ], :unique => true, :name => 'keyword_subscriptions_story_idx'
    add_index :keyword_subscriptions, [ :keyword_id, :story_id ], :unique => true, :name => 'keyword_subscriptions_kw_idx'
    
  end
  
  def self.down
    drop_table :keyword_subscriptions
    drop_table :keywords
    remove_column :story_metrics, :keyword_exists
  end
  
end
