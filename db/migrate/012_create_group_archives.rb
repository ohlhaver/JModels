class CreateGroupArchives < ActiveRecord::Migration
  
  def self.up
    
    # Create a MyISAM table
    create_table :story_group_archives, :options => DB::Engine::MyISAM, :id => false do |t|
      t.integer   :bj_session_id
      t.integer   :group_id
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
      t.datetime  :created_at
    end
    add_index :story_group_archives, [ :bj_session_id, :group_id ], :name => 'sg_archive_idx', :unique => true
    
    # Story Group Stories
    create_table :story_group_membership_archives, :id => false, :options => DB::Engine::MyISAM do |t|
      t.integer :bj_session_id
      t.integer :group_id
      t.integer :story_id
      t.integer :source_id      # story source_id
      t.integer :created_at     # story created at
      t.float   :quality_rating # story quality rating
      t.float   :blub_score     # story blub score
    end
    add_index :story_group_membership_archives, [ :group_id, :story_id ], :unique => true, :name => 'sgm_archive_idx'
    
  end
  
  def self.down
    
    drop_table :story_group_archives
    drop_table :story_group_membership_archives
    
  end
  
end