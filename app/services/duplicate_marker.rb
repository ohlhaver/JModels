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
    
    # db.create_table :shadow_candidate_similarities, :force => true, :id => false do |t|
    #   t.integer :story1_id
    #   t.integer :story2_id
    #   t.integer :frequency
    # end
    # 
    # db.add_index :shadow_candidate_similarities, [ :story1_id, :story2_id ], :unique => true
    # 
    # db.execute( 'INSERT INTO shadow_candidate_similarities (story1_id, story2_id, frequency) SELECT story1_id, story2_id, frequency FROM candidate_similarities' )
    # 
    # db.execute( 'DELETE * FROM candidate_similarities' )
    
    # Finding Duplicate Stories Inside the Story Group
    
    db.execute('DELETE FROM candidate_similarities WHERE story1_id NOT IN ( SELECT candidate_stories.id FROM candidate_stories )')
    db.execute('DELETE FROM candidate_similarities WHERE story2_id NOT IN ( SELECT candidate_stories.id FROM candidate_stories )')
    
    StoryGroup.current_session.find_each do |group|
      story_ids = group.stories.all( :select => 'id' ).collect{ |x| x.id }
      story_ids.each do |s1_id|
        story_ids.each do |s2_id|
          db.execute( DB::Insert::Ignore + 'INTO candidate_similarities (story1_id, story2_id) VALUES (' + db.quote_and_merge( s1_id, s2_id ) + ')' )
        end
      end
    end
    
    # db.execute( 'UPDATE candidate_similarities SET frequency = ( SELECT s.frequency FROM shadow_candidate_similarities AS s 
    #   WHERE s.story1_id = candidate_similarities.story1_id AND s.story2_id = candidate_similarities.story2_id )' )
    # 
    # db.drop_table( :shadow_candidate_similarities )
    
    db.execute( 'UPDATE candidate_similarities SET frequency = ( SELECT COUNT(*) FROM keyword_subscriptions WHERE story_id = story1_id ) 
      WHERE story1_id = story2_id AND frequency IS NULL' )
    
    db.create_table( 'story_keyword_ids', :force => true ) do |t|
    end
    
    story_ids = db.select_values( 'SELECT story1_id FROM candidate_similarities WHERE frequency IS NULL GROUP BY story1_id' )
    
    story_ids.each do | story_id |
      db.execute( 'DELETE FROM story_keyword_ids' )
      db.execute(  DB::Insert::Ignore + 'INTO story_keyword_ids (id) SELECT keyword_id FROM keyword_subscriptions WHERE story_id = ' + db.quote( story_id ) )
      db.execute( 'UPDATE candidate_similarities SET frequency = ( SELECT COUNT(*) FROM story_keyword_ids 
          INNER JOIN keyword_subscriptions ON ( story_keyword_ids.id = keyword_subscriptions.keyword_id ) 
          WHERE story_id = candidate_similarities.story2_id ) 
        WHERE frequency IS NULL AND story1_id = ' + db.quote( story_id ) )
    end
    
    db.drop_table( 'story_keyword_ids' )
    
    logger.info( 'Candidate Similarities Table Size: ' + db.select_value( 'SELECT COUNT(*) FROM candidate_similarities' ) + ' Rows.' )

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
        next unless story.master_id
        master_db.execute( MasterDB::Insert::Ignore + 'INTO story_metrics ( story_id ) VALUES(' + db.quote( story.id ) + ')')
        story_metric = StoryMetric.find( :first, :conditions => { :story_id => story.id  } )
        story_metric.update_attributes( :master_id => story.master_id ) # sphinx  & story_group_memberships callback necessary
        #master_db.execute( 'UPDATE story_metrics SET master_id = ' + db.quote( story.master_id ) + ' WHERE story_id = ' + db.quote( story.id ) )
      end
    end
    
  end
  
  def finalize( options = {} )
    db.drop_table( 'duplicate_stories' )
    db.drop_table( 'duplicate_candidates' )
    db.drop_table( 'duplicate_groups' )
  end
  
end