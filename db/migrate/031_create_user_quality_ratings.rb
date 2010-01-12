class CreateUserQualityRatings < ActiveRecord::Migration
  def self.up
    
    create_table :story_user_quality_ratings, :id => false do |t|
      t.integer   :story_id
      t.integer   :user_id
      t.integer   :preference
      t.float     :quality_rating, :default => 1, :null => false
      t.boolean   :source, :default => false, :null => :false
      t.timestamp :created_at
    end
    add_index :story_user_quality_ratings, :created_at
    add_index :story_user_quality_ratings, [ :story_id, :user_id ], :unique => true, :name => :story_user_quality_ratings_unique_idx
    add_index :story_user_quality_ratings, [ :preference, :story_id, :user_id ], :unique => true, :name => :story_user_quality_ratings_unique_idx2
    add_index :story_user_quality_ratings, [ :preference, :source, :story_id, :user_id ], :unique => true, :name => :story_user_quality_ratings_unique_idx3
    
    execute %Q(
      CREATE VIEW ban_user_quality_ratings AS SELECT story_id, user_id FROM story_user_quality_ratings WHERE preference = 0;
    )
    
    execute %Q(
      CREATE VIEW author_low_user_quality_ratings AS SELECT story_id, user_id FROM story_user_quality_ratings WHERE preference = 1 AND source = #{quoted_false};
    )
    
    execute %Q(
      CREATE VIEW author_normal_user_quality_ratings AS SELECT story_id, user_id FROM story_user_quality_ratings WHERE preference = 2 AND source = #{quoted_false};
    )
    
    execute %Q(
      CREATE VIEW author_high_user_quality_ratings AS SELECT story_id, user_id FROM story_user_quality_ratings WHERE preference = 3 AND source = #{quoted_false};
    )
    
    execute %Q(
      CREATE VIEW source_low_user_quality_ratings AS SELECT story_id, user_id FROM story_user_quality_ratings WHERE preference = 1 AND source = #{quoted_true};
    )
    
    execute %Q(
      CREATE VIEW source_normal_user_quality_ratings AS SELECT story_id, user_id FROM story_user_quality_ratings WHERE preference = 2 AND source = #{quoted_true};
    )
    
    execute %Q(
      CREATE VIEW source_high_user_quality_ratings AS SELECT story_id, user_id FROM story_user_quality_ratings WHERE preference = 3 AND source = #{quoted_true};
    )
    
    add_column :stories, :quality_ratings_generated, :boolean, :null => :false, :default => false
    add_column :stories, :author_quality_rating, :float
    add_column :stories, :source_quality_rating, :float
    
    Story.update_all( 'quality_ratings_generated = ' + quoted_true )
    add_index :stories, :quality_ratings_generated, :name => 'story_quality_ratings_generation_status_idx'
    
  end

  def self.down
    execute %Q( DROP VIEW ban_user_quality_ratings )
    execute %Q( DROP VIEW author_low_user_quality_ratings )
    execute %Q( DROP VIEW author_normal_user_quality_ratings )
    execute %Q( DROP VIEW author_high_user_quality_ratings )
    execute %Q( DROP VIEW source_low_user_quality_ratings )
    execute %Q( DROP VIEW source_normal_user_quality_ratings )
    execute %Q( DROP VIEW source_high_user_quality_ratings )
    drop_table :story_user_quality_ratings
    remove_column :stories, :author_quality_rating
    remove_column :stories, :source_quality_rating
    remove_index  :stories, :name => 'story_quality_ratings_generation_status_idx'
    remove_column :stories, :quality_ratings_generated
  end
  
end
