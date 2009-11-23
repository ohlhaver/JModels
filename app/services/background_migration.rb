class BackgroundMigration < BackgroundService
  
  def start( options = {} )
    
    unless db.table_exists?( :languages )
      db.create_table( :languages ) do |t|
        t.string  :code,              :limit => 10, :default => "", :null => false
        t.integer :cluster_threshold, :default => 5,  :null => false
      end
    end
    
    sync_languages_data()
    
    unless db.table_exists?( :candidate_stories )
      db.create_table( :candidate_stories ) do |t|
        t.integer :master_id
        t.integer :language_id
        t.integer :source_id
        t.integer :category_id
        t.boolean :is_video
        t.boolean :is_blog
        t.boolean :is_opinion
        t.boolean :keyword_exists
        t.boolean :thumbnail_exists
        t.float   :quality_rating
        t.datetime :created_at
      end
    end
    
    unless db.table_exists?( :keywords )
      db.create_table( :keywords ) do |t|
        t.string  :name, :length => 40
        t.integer :language_id
      end
      db.add_index :keywords, [ :language_id, :name ], :unique => true
    end
    
    unless db.table_exists?( :keyword_subscriptions )
      db.create_table :keyword_subscriptions do |t|
        t.integer :story_id
        t.integer :keyword_id
        t.integer :frequency
        t.integer :excerpt_frequency
      end
      db.add_index :keyword_subscriptions, [ :story_id, :keyword_id ], :unique => true, :name => 'keyword_subscriptions_story_idx'
      db.add_index :keyword_subscriptions, [ :keyword_id, :story_id ], :unique => true, :name => 'keyword_subscriptions_kw_idx'
    end
    
  end
  
  def finalize( options = {} )
  end
  
  protected
  
  def sync_languages_data
    db.transaction do
      db.execute('DELETE FROM languages')
      Language.find_each( :select => 'id, code, cluster_threshold') do |l|
        db.execute( DB::Insert::Ignore + 'INTO languages ( id, code, cluster_threshold ) VALUES (' +  "#{l.id}, '#{l.code}', #{l.cluster_threshold}" + ')')
      end
    end
  end
  
end