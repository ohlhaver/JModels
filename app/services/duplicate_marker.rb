#
# Find duplicates amongst the stories in  candidate_stories table
# The information is also stored back in story_metrics table
#
class DuplicateStory < BackgroundServiceDB
  set_table_name :duplicate_stories
end

class DuplicateMarker < BackgroundService

  def start( options = {} )
    
    populate_candidate_story_keywords
    
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
    
    logger.info( 'Duplicate Stories with Correct Leader Found. Updating the Background and MasterDB' )
    
    #
    # Step 5: Candidate Stories Update
    #
    db.execute( 'UPDATE candidate_stories 
      SET master_id = ( SELECT duplicate_stories.master_id 
      FROM duplicate_stories WHERE duplicate_stories.id = candidate_stories.id )' )
    
    #
    # Step 6: Master DB Update
    #
    DuplicateStory.find_each do |story|
      master_db.transaction do
        next unless story.master_id
        master_db.execute( MasterDB::Insert::Ignore + 'INTO story_metrics ( story_id ) VALUES(' + db.quote( story.id ) + ')')
        story_metric = StoryMetric.find( :first, :conditions => { :story_id => story.id  } )
        story_metric.update_attributes( :master_id => story.master_id ) # sphinx  & story_group_memberships callback necessary
        #master_db.execute( 'UPDATE story_metrics SET master_id = ' + db.quote( story.master_id ) + ' WHERE story_id = ' + db.quote( story.id ) )
      end
    end
    
  end
  
  def finalize( options = {} )
    [ 'duplicate_stories', 'duplicate_candidates', 'duplicate_groups' ].each do |table|
      db.drop_table table if db.table_exists?( table )
    end
  end
  
  
  def populate_candidate_story_keywords
    
    # Algorithm
    # For each group
    #  For each story in group
    #   Insert into the candidate_story_keywords
    #   Group for the each keyword
    #   Calculate the story story keyword in memory( Ruby )
    #   Insert into the candidate stories
    #
    
    db.create_table( 'candidate_story_keywords', :force => true, :id => false ) do |t|
      t.integer :story_id
      t.integer :keyword_id
      t.integer :frequency
    end
    db.add_index :candidate_story_keywords, [ :keyword_id, :story_id ], :unique => true, :name => 'cdd_story_keywords_idx'
    
    db.execute('DELETE FROM candidate_similarities WHERE story1_id NOT IN ( SELECT candidate_stories.id FROM candidate_stories )')
    db.execute('DELETE FROM candidate_similarities WHERE story2_id NOT IN ( SELECT candidate_stories.id FROM candidate_stories )')
    new_story_ids = db.select_values( 'SELECT id FROM candidate_stories LEFT OUTER JOIN candidate_similarities 
      ON ( story1_id = story2_id AND story1_id = id ) WHERE story1_id IS NULL' ).group_by{ |x| x }
    pair_hash = Hash.new{ |h,k| h[k] = Hash.new{ |sh, sk| sh[sk] = 0 } } # Pairwise Frequency Count Holder
    
    return if new_story_ids.blank?
    
    # StoryGroup
    StoryGroup.current_session.find_each do |group|
      
      story_ids = group.stories.all( :select => 'id' ).collect{ |x| x.id }
      
      db.execute( 'INSERT INTO candidate_story_keywords ( story_id, keyword_id, frequency ) 
        SELECT keyword_subscriptions.story_id, keyword_subscriptions.keyword_id, keyword_subscriptions.frequency
        FROM keyword_subscriptions WHERE keyword_subscriptions.story_id IN (' + story_ids.join(',') + ')' )
      
      story_ids_groups = db.select_values( 'SELECT GROUP_CONCAT( story_id ) FROM candidate_story_keywords GROUP by keyword_id' )
      
      while( story_ids = story_ids_groups.pop )
        new_story_ids_in_a_group, old_story_ids_in_a_group = story_ids.to_s.split(',').partition{ |x| !new_story_ids[x].nil? }
        while( s1_id = new_story_ids_in_a_group.pop )
          pair_hash[ s1_id ][ s1_id ] += 1
          new_story_ids_in_a_group.each do |s2_id|
            pair_hash[s1_id][s2_id] += 1
            pair_hash[s2_id][s1_id] += 1
          end if new_story_ids_in_a_group.any?
          old_story_ids_in_a_group.each do |s2_id|
            pair_hash[s1_id][s2_id] += 1
            pair_hash[s2_id][s1_id] += 1
          end if old_story_ids_in_a_group.any?
        end
      end
      
      db.execute( 'DELETE FROM candidate_story_keywords' )
      
    end
    
    # ( ss1.frequency / ( ss2.frequency + ss3.frequency - ss1.frequency )  >= 0.90 )
    pair_hash.each do | s1_id, s1_hash |
      db.transaction do
        s1_hash.each do | s2_id, a_int_b_frequency |
          next if pair_hash[s1_id][s1_id].zero? || pair_hash[s2_id][s2_id].zero?
          a_union_b_frequency = pair_hash[s1_id][s1_id] + pair_hash[s2_id][s2_id] - a_int_b_frequency
          next if (a_int_b_frequency * 100 )/a_union_b_frequency < 90
          db.execute( DB::Insert::Ignore + 'INTO candidate_similarities (story1_id, story2_id, frequency ) VALUES( ' +
            db.quote_and_merge( s1_id, s2_id, pair_hash[s1_id][s1_id] ) + ')' ) ## Inserting s1 frequency
        end
      end
    end
    
    pair_hash.each{ |k,v| v.clear }.clear
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
      SELECT story1_id as story_id, story2_id as master_id, frequency as frequency
      FROM candidate_similarities' ) #  |A intersection B| / |A union B|
          
    db.add_index 'duplicate_groups', [ :story_id, :master_id ], :name => 'dup_grp_idx'
    
    
  end
end