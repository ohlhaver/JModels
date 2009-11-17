#
# Group the stories inside candidate_stories table into groups 
# Also store the groups into Group table
#
class GroupGeneration < BackgroundService
  
  def start( options = {} )
    
    db.create_table( 'candidate_story_keywords', :force => true, :id => false ) do |t|
      t.integer :story_id
      t.integer :keyword_id
    end
    
    #
    # Select non duplicate stories and select related excerpt keywords
    #
    db.execute( 'INSERT OR IGNORE INTO candidate_story_keywords ( story_id, keyword_id ) 
      SELECT keyword_subscriptions.story_id, keyword_subscriptions.keyword_id
      FROM keyword_subscriptions INNER JOIN candidate_stories ON ( candidate_stories.id = keyword_subscriptions.story_id )
      WHERE keyword_subscriptions.excerpt_frequency IS NOT NULL AND 
      candidate_stories.master_id IS NULL' )
        
    db.add_index :candidate_story_keywords, [ :keyword_id, :story_id ], :unique => true
    
    db.create_table( 'related_candidates', :id => false, :force => true ) do |t|
      t.integer :story1_id
      t.integer :story2_id
      t.integer :frequency # common to both story1_id and story2_id
    end
    
    db.transaction do
      
      db.execute( 'INSERT OR IGNORE INTO related_candidates ( story1_id, story2_id, frequency )
        SELECT  ks1.story_id AS story1_id, ks2.story_id AS story2_id, COUNT( ks1.keyword_id ) AS frequency 
        FROM candidate_story_keywords AS ks1
        INNER JOIN candidate_story_keywords AS ks2 ON ( ks1.keyword_id = ks2.keyword_id )
        GROUP BY ks1.story_id, ks2.story_id' )
      
      # Cluster Threshold is language specific setting. It is the minimum number of keywords that two stories must match in order to be related
      
      db.execute( 'DELETE FROM related_candidates 
        WHERE frequency < ( 
          SELECT COALESCE( languages.cluster_threshold, 5 )
          FROM candidate_stories 
          LEFT OUTER JOIN languages ON ( candidate_stories.language_id = languages.id ) 
          WHERE candidate_stories.id = story1_id )' )
      
    end
    
    db.add_index 'related_candidates', [ :story1_id, :story2_id ], :unique => true
    
    db.create_table( 'candidate_groups', :force => true ) do |t|
      t.integer :story_count
      t.integer :source_count
      t.integer :language_id
    end
    
    #
    # Overlapping and Redundant Groups
    #
    db.execute( 'INSERT OR IGNORE INTO candidate_groups ( id, story_count, source_count, language_id ) 
      SELECT story1_id, COUNT(*) AS story_count, COUNT( DISTINCT source_id ) AS source_count, language_id 
      FROM related_candidates 
      LEFT OUTER JOIN candidate_stories ON ( candidate_stories.id = related_candidates.story2_id )
      GROUP BY story1_id HAVING story_count > 1 AND source_count > 1' )
      
    logger.debug('Possible Candidate Groups')
    
    #
    # Background Processor Memory and CPU Intensive Task
    #
    grouped_stories = db.select_all( 'SELECT candidate_groups.id, GROUP_CONCAT( story2_id ) AS story_ids, 
          candidate_groups.language_id, candidate_groups.story_count
      FROM candidate_groups 
      INNER JOIN related_candidates ON ( related_candidates.story1_id = candidate_groups.id )
      GROUP BY candidate_groups.id' )
    
    final_groups = []
    
    grouped_stories.each { |group|
      puts group['id']
      puts group['story_ids']
    }
    
    bm = Benchmark.measure {
      grouped_stories.each{ |h| h.merge!( 'story_count' => h['story_count'].to_i, 'story_ids' => h['story_ids'].split(',') ) }
      heap = Containers::Heap.new( grouped_stories ){ |x, y| ( x['story_count'] <=> y['story_count'] ) == 1 }
      while( group = heap.pop ) # Maximum story_count
        final_groups << group
        heap.clear # Remove all elements
        grouped_stories.each{ |x|
          if x == group || group['story_ids'].include?( x['id'] )
            x['delete'] = true
            next
          end
          story_ids = x['story_ids'] - group['story_ids']
          x.merge!( 'story_ids' => story_ids, 'story_count' => story_ids.size )
          heap.push( x ) if story_ids.size > 1
        }
        grouped_stories.delete_if{ |x| x['delete'] || x['story_count'] < 2  }
        puts "Finding best group amongst #{grouped_stories.size} groups"
      end
    }
    
    logger.info("Heap Based Group Selection Performance: Found #{final_groups.size} Groups\n" + Benchmark::Tms::CAPTION + (bm).to_s)
    
    return if final_groups.empty?
    
    @session ||= BjSession.create( :job_id => self.job_id )
    
    #
    # Removing Overlapping and Redundant Groups
    #
    db.execute( 'DELETE FROM candidate_groups WHERE id NOT IN (' + final_groups.collect{ |x| x['id'] }.join(',') +  ')')
    
    #
    # Relating Stories with the Groups
    #
    db.create_table( 'candidate_group_stories', :id => false, :force => true ) do |t|
      t.integer :group_id
      t.integer :story_id
    end
    
    db.transaction do
      final_groups.each do | group|
        group_id = group['id'].to_s
        puts "#{group_id}: #{group['story_count']}: #{group['story_ids'].join(',')}"
        group['story_ids'].each do |story_id|
          db.execute('INSERT INTO candidate_group_stories (group_id, story_id) VALUES(' + group_id + ',' + story_id.to_s + ')')
        end
      end
    end
    
    db.add_index( 'candidate_group_stories', [:group_id, :story_id], :unique => true )
    
    #
    # Getting complete data for the Final Group Creation
    #
    final_groups = db.select_all( 'SELECT candidate_groups.id AS pilot_story_id, candidate_groups.language_id, 
      GROUP_CONCAT( story_id ) AS story_ids, 
      GROUP_CONCAT( category_id ) AS category_ids,
      COUNT(*) AS story_count, COUNT(DISTINCT candidate_stories.source_id) AS source_count
      FROM candidate_groups 
      INNER JOIN candidate_group_stories ON ( candidate_group_stories.group_id = candidate_groups.id )
      LEFT OUTER JOIN candidate_stories ON ( candidate_stories.id = candidate_group_stories.story_id )
      GROUP BY candidate_groups.id' )
    
    Group.transaction do
      final_groups.each do | group |
        category_ids = group.delete( 'category_ids' ).split(',').collect!{ |x| x.to_i }
        group.merge!( 'category_id' => Category.top_category_id( category_ids ), 'bj_session_id' => @session.id )
        Group.create( group )
      end
    end
    
  end
  
  def finalize( options = {} )
    
    [ 'candidate_group_stories', 'candidate_groups', 'related_candidates', 'candidate_story_keywords' ].each do |table|
      db.drop_table table if db.table_exists?( table )
    end
    
  end
  
end