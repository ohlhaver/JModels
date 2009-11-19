
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
    create_table :story_groups do |t|
      t.integer   :bj_session_id
      t.integer   :pilot_story_id
      t.integer   :category_id
      t.integer   :language_id
      t.string    :top_keywords  # top 3 keywords
      t.integer   :story_count   # ( originally weight )
      t.integer   :source_count  
      t.integer   :video_count
      t.integer   :blog_count
      t.integer   :opinion_count
      t.float     :broadness_score
      t.integer   :thumbnail_story_id
      t.boolean   :thumbnail_exists
      t.datetime  :created_at
    end
    add_index :story_groups,  [ :bj_session_id, :language_id, :broadness_score, :category_id ], :name => 'story_groups_idx_1'
    add_index :story_groups, [ :bj_session_id, :language_id, :category_id, :broadness_score ], :name => 'story_groups_idx_2'
    
    # 
    # Story Group Stories
    #
    create_table :story_group_memberships, :id => false do |t|
      t.integer :group_id
      t.integer :story_id
      t.integer :source_id      # story source_id
      t.integer :created_at     # story created at
      t.float   :quality_rating # story quality rating
      t.float   :blub_score     # story blub score
    end
    add_index :story_group_memberships, [ :group_id, :story_id ], :unique => true
    
  end
  
  def self.down
    drop_table :story_group_memberships
    drop_table :story_groups
    drop_table :bj_sessions
  end
  
end
