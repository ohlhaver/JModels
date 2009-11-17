
class CreateClusterTables < ActiveRecord::Migration
  
  def self.up
    #
    # Background Job Sessions ( Which Iteration is Running )
    #
    create_table :bj_sessions do |t|
      t.integer  :job_id
      t.datetime :created_at
      t.float    :duration # How much time it took to run the bj ( in Seconds )
    end
    add_index :bj_sessions, [ :job_id, :created_at ]
    
    #
    # Story Groups
    #
    create_table :groups do |t|
      t.integer :bj_session_id
      t.integer :pilot_story_id
      t.integer :category_id
      t.integer :language_id
      t.string  :story_ids, :limit => 2000
      t.integer :story_count   # ( originally weight )
      t.integer :source_count  # ( originally broadness )
      t.datetime :created_at
    end
    add_index :groups, [ :bj_session_id, :source_count ]
    
    #
    # Story Clusters
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
    
  end
  
  def self.down
    drop_table :clusters
    drop_table :groups
    drop_table :bj_sessions
  end
  
end
