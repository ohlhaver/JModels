#
# Find duplicates amongst the stories in  candidate_stories table
# The information is also stored back in story_metrics table
#
class DuplicateStory < BackgroundServiceDB
  set_table_name :duplicate_stories
end

class DuplicateMarker < BackgroundService

  def start( options = {} )
    
    #
    # Step 1: Candidate Story Similarities
    # 
    db.create_table( 'candidate_similarities', :force => true, :id => false ) do |t|
      t.integer :story1_id
      t.integer :story2_id
      t.integer :frequency
    end
    
    # This is the bottleneck takes the maximum time
    db.execute( 'INSERT INTO candidate_similarities ( story1_id, story2_id, frequency )
      SELECT  ks1.story_id AS story1_id, ks2.story_id AS story2_id, COUNT( ks1.keyword_id ) AS frequency 
      FROM keyword_subscriptions AS ks1
      INNER JOIN keyword_subscriptions AS ks2 ON ( ks1.keyword_id = ks2.keyword_id )
      GROUP BY ks1.story_id, ks2.story_id' )
        
    db.add_index 'candidate_similarities', [ :story1_id, :story2_id, :frequency ], :name => 'cdd_story_similarity_idx'
    
    #
    # Step 2: Generate Duplicate Stories Groups
    #
    db.create_table( 'duplicate_groups', :force => true, :id => false ) do |t|
      t.integer :story_id
      t.integer :master_id
      t.integer :frequency # keyword frequency count in story_id
    end
    
    db.execute( 'INSERT INTO duplicate_groups ( story_id, master_id, frequency )
      SELECT ss1.story1_id as story_id, ss1.story2_id as master_id, ss2.frequency as frequency
      FROM candidate_similarities AS ss1 
      LEFT OUTER JOIN candidate_similarities AS ss2 ON ( ss1.story1_id = ss2.story1_id  AND ss1.story1_id = ss2.story2_id ) 
      LEFT OUTER JOIN candidate_similarities AS ss3 ON ( ss1.story2_id = ss3.story1_id  AND ss1.story2_id = ss3.story2_id )
      WHERE ( ss1.frequency IS NOT NULL )
        AND ( ss1.frequency / ( ss2.frequency + ss3.frequency - ss1.frequency )  >= 0.90 )' ) #  |A intersection B| / |A union B|
          
    db.add_index 'duplicate_groups', [ :story_id, :master_id ], :name => 'dup_grp_idx'
    
    
    #
    # Step 3: Duplicate Stories with Incorrect Leader
    #
    db.create_table( 'duplicate_candidates', :force => true ) do |t|
      t.integer :master_id
      t.integer :frequency # story keyword count
      t.integer :group_count
    end
    
    # Get the story groups merge them and store the duplicate stories
    db.transaction do
      db.execute( 'INSERT INTO duplicate_candidates( id, master_id, group_count, frequency )
        SELECT story_id, MIN( master_id ) as master_id, COUNT( master_id ) as group_count, frequency FROM  duplicate_groups
        GROUP BY story_id' )
      # Delete those groups which are less than 2 stories
      db.execute( 'DELETE FROM duplicate_candidates WHERE group_count IS NULL OR group_count < 2' )
    end
    
    db.add_index 'duplicate_candidates', [:master_id, :frequency], :name => 'dup_cdd_idx'
    
    #
    # Step 4: Duplicate Stories with Correct Leader
    #
    db.create_table( 'duplicate_stories', :force => true ) do |t|
      t.integer :master_id
    end
    
    # Choosing the correct leader with max number of keywords
    db.transaction do
      db.execute( 'INSERT INTO duplicate_stories (id, master_id) 
        SELECT id, master_id FROM ( 
          SELECT s2.id as id, s1.id as master_id, s1.frequency, MAX(s1.frequency) AS max_frequency
            FROM duplicate_candidates AS s1 
            INNER JOIN duplicate_candidates AS s2 ON (s1.master_id = s2.master_id)
            GROUP BY s2.id HAVING s1.frequency = max_frequency
        ) AS t ' )
      db.execute( 'UPDATE duplicate_stories SET master_id = NULL WHERE master_id = id' )
      db.execute( DB::Insert::Ignore + 'INTO duplicate_stories (id, master_id) SELECT id, NULL FROM candidate_stories' )
    end
    
    #
    # Step 5: Candidate Stories Update
    #
    db.execute( 'UPDATE candidate_stories 
      SET master_id = ( SELECT duplicate_stories.master_id 
      FROM duplicate_stories WHERE duplicate_stories.id = candidate_stories.id )' )
    
    #
    # Step 6: Master DB Update
    #
    master_db.transaction do
      DuplicateStory.find_each do |story|
        master_db.execute( MasterDB::Insert::Ignore + 'INTO story_metrics ( story_id ) VALUES(' + db.quote( story.id ) + ')')
        master_db.execute( 'UPDATE story_metrics SET master_id = ' + db.quote( story.master_id ) + ' WHERE story_id = ' + db.quote( story.id ) )
      end
    end
    
  end
  
  def finalize( options = {} )
    db.drop_table( 'duplicate_stories' )
    db.drop_table( 'duplicate_candidates' )
    db.drop_table( 'duplicate_groups' )
    db.drop_table( 'candidate_similarities' )
  end
  
end