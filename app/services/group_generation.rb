#
# Group the stories inside candidate_stories table into groups of related stories
#
class GroupGeneration < BackgroundService
  
  def start( options = {} )
    
    return if exit?
    benchmark( 'Populate Candidate Group Similarities' ){ populate_candidate_story_keywords }
     # pre step to find related stories
    
    return if exit?
    benchmark( 'Greedy Group Formation' ){ find_and_populate_candidate_groups_per_story }
     # greedy group formation
    
    return if exit?
    benchmark( 'Final Group Formation'){ reduce_candidate_groups_to_relevant_candidate_groups }# optimal group formation
    
    return if @final_groups.empty? # No groups found
    
    return if exit?
    benchmark( 'Group Memberships Generation' ){ populate_candidate_group_memberships }
    
    return if exit?
    benchmark( 'Top Keyword Generation' ){ populate_top_3_keywords_per_candidate_group }
    
    return if exit?
    @session ||= BjSession.create( :job_id => self.job_id )
    benchmark( 'Master DB Story Group' ){ populate_story_groups_table_from_final_groups }
    
    benchmark( 'Cluster Group Mappings' ){ cluster_group_mappings }
    
    benchmark( 'Archiving Old Group' ){ archive_old_groups }
  end
  
  def finalize( options = {} )
    
    [ 'candidate_group_top_keywords', 'candidate_group_keywords', 'candidate_group_stories', 
      'candidate_groups', 'related_candidates', 'candidate_story_keywords' ].each do |table|
      db.drop_table table if db.table_exists?( table )
    end
    
  end
  
  
  protected
  
  #
  # For each candidate story eligible for group generation
  #  store excerpt keywords and their frequency with the story
  #
  def populate_candidate_story_keywords
    
    db.create_table( 'candidate_story_keywords', :force => true, :id => false ) do |t|
      t.integer :story_id
      t.integer :keyword_id
      t.integer :frequency
    end
    db.execute('DELETE FROM keyword_subscriptions WHERE story_id NOT IN ( SELECT candidate_stories.id FROM candidate_stories )')
    #db.execute('DELETE FROM keyword_subscriptions WHERE story_id IN ( SELECT candidate_stories.id FROM candidate_stories WHERE candidate_stories.master_id IS NOT NULL )')
    
    #
    # Select stories and select related excerpt keywords
    #
    db.execute( 'INSERT INTO candidate_story_keywords ( story_id, keyword_id, frequency ) 
      SELECT keyword_subscriptions.story_id, keyword_subscriptions.keyword_id, keyword_subscriptions.excerpt_frequency
      FROM keyword_subscriptions INNER JOIN candidate_stories ON ( candidate_stories.id = keyword_subscriptions.story_id )
      WHERE keyword_subscriptions.excerpt_frequency IS NOT NULL AND candidate_stories.master_id IS NULL' )
        
    db.add_index :candidate_story_keywords, [ :keyword_id, :story_id ], :unique => true, :name => 'cdd_story_keywords_idx'
    
    db.execute('DELETE FROM candidate_group_similarities WHERE story1_id NOT IN ( SELECT candidate_stories.id FROM candidate_stories )')
    db.execute('DELETE FROM candidate_group_similarities WHERE story2_id NOT IN ( SELECT candidate_stories.id FROM candidate_stories )')
    db.execute('DELETE FROM candidate_group_similarities WHERE story1_id IN ( SELECT candidate_stories.id FROM candidate_stories WHERE candidate_stories.master_id IS NOT NULL )')
    db.execute('DELETE FROM candidate_group_similarities WHERE story2_id IN ( SELECT candidate_stories.id FROM candidate_stories WHERE candidate_stories.master_id IS NOT NULL )')
    
    #
    # For Incremental Calculations to Speed Up Things
    #
    new_story_ids = db.select_values( 'SELECT id FROM candidate_stories LEFT OUTER JOIN candidate_group_similarities 
      ON ( story1_id = story2_id AND story1_id = id ) WHERE story1_id IS NULL AND candidate_stories.master_id IS NULL LIMIT 5000' ).group_by{ |x| x }
      
    unless new_story_ids.blank?
      
      story_ids_groups = db.select_values( 'SELECT GROUP_CONCAT( story_id ) FROM candidate_story_keywords GROUP by keyword_id' )
      
      pair_hash = Hash.new{ |h,k| h[k] = Hash.new{ |sh, sk| sh[sk] = 0 } } # Pairwise Frequency Count Holder
      
      #
      # In Memory Calculations of the Keyword Frequency in Incremental Mode
      #
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
      
      new_story_ids.clear
      min_frequency = db.select_value( 'SELECT MIN(COALESCE(cluster_threshold,5)) FROM languages;').to_i
      
      pair_hash.each do | s1_id, s1_hash |
        db.transaction do
          s1_hash.each do | s2_id, frequency |
            next if s1_id != s2_id && frequency < min_frequency
            db.execute( DB::Insert::Ignore + 'INTO candidate_group_similarities (story1_id, story2_id, frequency ) VALUES( ' +
              db.quote_and_merge( s1_id, s2_id, frequency ) + ')' )
          end
        end
      end
      
    end
    
    logger.info( 'Candidate Group Similarities Table: ' + db.select_value('SELECT COUNT(*) FROM candidate_group_similarities') + ' Rows' )
    
  end
  
  
  #
  # For each pair of stories find number of excerpt keywords common to both ( frequency )
  # Based on the frequency and language specific threshold 
  #  for each story create a group of stories related to the story 
  #
  def find_and_populate_candidate_groups_per_story
    
    #
    # Step 1: Candidate Story Similarities
    #
    
    # Step 2: Find Related Stories based on Keyword Matching and Language Specific Threshold
    db.create_table( 'related_candidates', :id => false, :force => true ) do |t|
      t.integer :story1_id
      t.integer :story2_id
      t.integer :frequency # common to both story1_id and story2_id
    end
  
    #db.transaction do
      
    # Cluster Threshold is language specific setting. It is the minimum number of keywords that two stories must match in order to be related
    db.execute( 'INSERT INTO related_candidates ( story1_id, story2_id, frequency ) 
      SELECT story1_id, story2_id, frequency FROM candidate_group_similarities
        LEFT OUTER JOIN candidate_stories ON ( candidate_stories.id = story1_id )
        LEFT OUTER JOIN languages ON ( candidate_stories.language_id = languages.id )
        WHERE frequency >= COALESCE( languages.cluster_threshold, 5 )' )
    
      # db.execute( DB::Insert::Ignore + 'INTO related_candidates ( story1_id, story2_id, frequency )
      #   SELECT  ks1.story_id AS story1_id, ks2.story_id AS story2_id, COUNT( ks1.keyword_id ) AS frequency 
      #   FROM candidate_story_keywords AS ks1
      #   INNER JOIN candidate_story_keywords AS ks2 ON ( ks1.keyword_id = ks2.keyword_id )
      #   GROUP BY ks1.story_id, ks2.story_id' )
      #    
      # db.execute( 'DELETE FROM related_candidates 
      #   WHERE frequency < ( 
      #     SELECT COALESCE( languages.cluster_threshold, 5 )
      #     FROM candidate_stories 
      #     LEFT OUTER JOIN languages ON ( candidate_stories.language_id = languages.id ) 
      #     WHERE candidate_stories.id = story1_id )' )
    
    #end
  
    db.add_index 'related_candidates', [ :story1_id, :story2_id ], :unique => true, :name => 'related_stories_idx'
    
    logger.info( 'Related Candidates Table: ' + db.select_value('SELECT COUNT(*) FROM related_candidates') + ' Rows' )
    
    db.create_table( 'candidate_groups', :force => true ) do |t|
      t.integer :story_count
      t.integer :source_count
      t.integer :language_id
    end
    
    #
    # Overlapping and Redundant Groups
    #
    db.execute( DB::Insert::Ignore + 'INTO candidate_groups ( id, story_count, source_count, language_id ) 
      SELECT story1_id, COUNT(*) AS story_count, COUNT( DISTINCT source_id ) AS source_count, language_id 
      FROM related_candidates 
      INNER JOIN candidate_stories ON ( candidate_stories.id = related_candidates.story2_id )
      GROUP BY story1_id HAVING story_count > 1 AND source_count > 1' )
    
  end
  
  #
  # For each group find the maximal group.
  # Insert maximal group into final groups.
  # Delete maximal group from candidate groups.
  # From each candidate group subtract the stories in the maximal group
  # Also remove the candidate group whose pilot story is member of maximal group
  # Repeat
  #
  def reduce_candidate_groups_to_relevant_candidate_groups
    
    grouped_stories = db.select_all( 'SELECT candidate_groups.id, GROUP_CONCAT( story2_id ) AS story_ids, 
          candidate_groups.language_id, candidate_groups.story_count
      FROM candidate_groups 
      INNER JOIN related_candidates ON ( related_candidates.story1_id = candidate_groups.id )
      GROUP BY candidate_groups.id' )
    
    @final_groups = []
    
    # Ruby Processing is Used
    # bm = Benchmark.measure {
    #   grouped_stories.each{ |h| h.merge!( 'story_count' => h['story_count'].to_i, 'story_ids' => h['story_ids'].split(',') ) }
    #   heap = Containers::Heap.new( grouped_stories ){ |x, y| ( x['story_count'] <=> y['story_count'] ) == 1 }
    #   while( group = heap.pop ) # Maximum story_count
    #     @final_groups << group
    #     heap.clear # Remove all elements
    #     grouped_stories.each{ |x|
    #       if x == group || group['story_ids'].include?( x['id'] )
    #         x['delete'] = true
    #         next
    #       end
    #       story_ids = x['story_ids'] - group['story_ids']
    #       x.merge!( 'story_ids' => story_ids, 'story_count' => story_ids.size )
    #       heap.push( x ) if story_ids.size > 1
    #     }
    #     grouped_stories.delete_if{ |x| x['delete'] || x['story_count'] < 2  }
    #   end
    # }
    #
    # logger.info("Heap Based Group Selection Performance: Found #{@final_groups.size} Groups\n" + Benchmark::Tms::CAPTION + (bm).to_s)
    #
    bm = Benchmark.measure {
      grouped_stories.each{ |h| h.merge!( 'story_count' => h['story_count'].to_i, 'story_ids' => h['story_ids'].split(',') ) }
      grouped_stories = grouped_stories.sort_by{ |x| -x['story_count'] }
      group_ids = Hash.new # Group that has been freezed
      story_ids = Hash.new # Stories that has been assigned a group
      grouped_stories.each{ |group|
        next if group_ids[ group['id'] ]
        group['story_ids'].delete_if{ |x| story_ids[x] }
        if group['story_ids'].size > 1
          group_ids[ group['id'] ] = true
          group['story_ids'].each{ |x| story_ids[x] = true }
          @final_groups << group if group['story_ids']
        end
      }
      group_ids.clear
      story_ids.clear
      grouped_stories.clear
    }
    
    logger.info("Greedy Heuristic Performance: Found #{@final_groups.size} Groups\n" + Benchmark::Tms::CAPTION + (bm).to_s)
    
    return if @final_groups.empty?
    
    #
    # Removing Overlapping and Redundant Groups
    #
    final_group_ids = @final_groups.collect{ |x| x['id'] }
    all_group_ids = db.select_values('SELECT id FROM candidate_groups')
    redundant_group_ids = all_group_ids - final_group_ids
    all_group_ids.clear
    final_group_ids.clear
    offset = 0
    while redundant_group_ids[ offset ]
      db.execute( 'DELETE FROM candidate_groups WHERE id IN (' + redundant_group_ids[ offset, 100 ].join(',') + ')')
      offset += 100
    end
    #db.execute( 'DELETE FROM candidate_groups WHERE id NOT IN (' + @final_groups.collect{ |x| x['id'] }.join(',') +  ')')
    
  end
  
  #
  # Create story to group memberships for all the final groups
  #
  def populate_candidate_group_memberships
    
    db.create_table( 'tmp_group_stories_map', :id => false, :force => true ) do |t|
      t.integer :group_id
      t.integer :story_id
    end
    
    @final_groups.each do | group|
      group_id = group['id'].to_s
      db.transaction do
        group['story_ids'].each do |story_id|
          db.execute( DB::Insert::Ignore + 'INTO tmp_group_stories_map (group_id, story_id) VALUES(' + group_id + ',' + story_id.to_s + ')')
          # 
          # duplicate_ids = db.select_values( "SELECT id, master_id FROM candidate_stories WHERE master_id IN #{story_id}" ) || []
          # duplicate_ids.each{ |dup_story_id| 
          #   db.execute( DB::Insert::Ignore + 'INTO tmp_group_stories_map (group_id, story_id) VALUES(' + group_id + ',' + dup_story_id.to_s + ')') 
          # }
        end
      end
    end
    
    db.create_table( 'candidate_group_stories', :id => false, :force => true ) do |t|
      t.integer  :group_id
      t.integer  :story_id
      t.integer  :source_id
      t.integer  :category_id
      t.integer  :master_id
      t.boolean  :is_video
      t.boolean  :is_blog
      t.boolean  :is_opinion
      t.boolean  :thumbnail_exists
      t.timestamp :created_at        # story created at
      t.float    :quality_rating
      t.float    :blub_score        # blub value ( time decay + source_rating )
      t.integer  :rank
    end
    
    db.execute('INSERT INTO candidate_group_stories ( group_id, story_id, source_id, category_id, master_id,
        is_video, is_blog, is_opinion, thumbnail_exists, created_at, quality_rating ) 
      SELECT tmp_group_stories_map.group_id, tmp_group_stories_map.story_id,  candidate_stories.source_id, candidate_stories.category_id, 
          candidate_stories.master_id, candidate_stories.is_video, candidate_stories.is_blog, candidate_stories.is_opinion, 
          candidate_stories.thumbnail_exists, candidate_stories.created_at, candidate_stories.quality_rating
      FROM tmp_group_stories_map 
      INNER JOIN candidate_stories ON ( candidate_stories.id =  tmp_group_stories_map.story_id )')
      
    db.drop_table( 'tmp_group_stories_map' )
    
    # blub =  age*quality_value
    db.execute('UPDATE candidate_group_stories SET blub_score = ( 100 / POWER( 1 + 
      IF( UTC_TIMESTAMP() > created_at, TIMESTAMPDIFF( HOUR, created_at, UTC_TIMESTAMP() ),  0 ), 0.33 ) ) * quality_rating')
    
    db.add_index( 'candidate_group_stories', [:group_id, :story_id ], :name => 'cdd_grp_stories_uniq_idx', :unique => true )
    db.add_index( 'candidate_group_stories', [:group_id, :blub_score], :name => 'cdd_grp_stories_idx' )
    
    db.select_all( 'SELECT cgs1.group_id, cgs1.story_id,  COALESCE( COUNT( cgs2.story_id ), 0 ) + 1 AS rank
      FROM candidate_group_stories as cgs1 
      LEFT OUTER JOIN candidate_group_stories as cgs2 ON ( cgs1.group_id = cgs2.group_id AND 
        ( cgs1.blub_score < cgs2.blub_score OR ( cgs1.blub_score = cgs2.blub_score && cgs1.created_at < cgs2.created_at ) ) )
      GROUP BY cgs1.group_id, cgs1.story_id' ).each do | record |
      db.execute("UPDATE candidate_group_stories SET rank = #{record['rank']} WHERE group_id = #{record['group_id']} AND story_id = #{record['story_id']}")
    end
    
  end
  
  #
  # Find Top 3 Keywords for each group using the keyword most popular to all the stories inside the group
  #
  def populate_top_3_keywords_per_candidate_group
    
    # Step6. Finding Group Keywords
    db.create_table( 'candidate_group_keywords', :id => false, :force => true ) do |t|
      t.integer :group_id
      t.integer :keyword_id
      t.integer :score
    end
    
    db.add_index 'candidate_group_keywords', [ :group_id, :score, :keyword_id ], :unique => true, :name => 'cdd_grp_keywords_idx'
    
    # Step7. Finding Top 3 Keywords for each group based on score
    db.create_table( 'candidate_group_top_keywords', :force => true ) do |t|
      t.string :keywords
    end
    
    @final_groups.each do |group|
      db.execute( DB::Insert::Ignore + %Q(INTO candidate_group_keywords ( group_id, keyword_id, score )
        SELECT #{group['id']}, keyword_id, COALESCE( COUNT( frequency )*SUM( frequency ), 0 ) AS score 
        FROM candidate_group_stories INNER JOIN candidate_story_keywords ON ( candidate_story_keywords.story_id = candidate_group_stories.story_id )
        WHERE candidate_group_stories.group_id = #{group['id']}
        GROUP BY candidate_story_keywords.keyword_id ) )
      top_keyword_ids = db.select_values( %Q(SELECT keyword_id FROM candidate_group_keywords WHERE group_id = #{group['id']} ORDER BY score DESC LIMIT 3) )
      top_keyword_ids = ['NULL'] if top_keyword_ids.blank?
      db.execute( %Q(DELETE FROM candidate_group_keywords WHERE group_id = #{group['id']} AND keyword_id NOT IN ( #{top_keyword_ids.join(',')} ) ) ) 
    end
    
    # debug = db.select_all( 'SELECT k1.group_id AS gid, keywords.name AS name, k1.score AS score, COUNT( k2.keyword_id ) AS count
    #   FROM candidate_group_keywords AS k1
    #   LEFT OUTER JOIN candidate_group_keywords AS k2 ON ( k2.group_id = k1.group_id AND 
    #   ( k1.score < k2.score OR ( k1.score = k2.score AND k1.keyword_id < k2.keyword_id ) ) )
    #   LEFT OUTER JOIN keywords ON ( keywords.id = k1.keyword_id )
    #   GROUP BY k1.keyword_id 
    #   ORDER BY k1.group_id ASC, k1.score DESC')
    # 
    # debug.each{ |record|
    #   puts "#{record['gid']}\t#{record['name']}\t#{record['score']}\t#{record['count']}"
    # }
    
    # db.execute( 'INSERT INTO candidate_group_top_keywords ( id, keywords ) 
    #     SELECT t.group_id, GROUP_CONCAT( keywords.name ) 
    #     FROM ( SELECT  k1.*
    #       FROM candidate_group_keywords AS k1
    #       LEFT OUTER JOIN candidate_group_keywords AS k2 ON ( k2.group_id = k1.group_id AND 
    #       ( k1.score < k2.score OR ( k1.score = k2.score AND k1.keyword_id < k2.keyword_id ) ) )
    #       GROUP BY k1.keyword_id
    #       HAVING COUNT( k2.keyword_id ) < 3 
    #       ORDER BY k1.group_id ASC, k1.score DESC ) AS t 
    #     LEFT OUTER JOIN keywords ON ( keywords.id = t.keyword_id ) GROUP BY t.group_id' )
    
    db.execute( 'INSERT INTO candidate_group_top_keywords ( id, keywords ) 
        SELECT candidate_group_keywords.group_id, GROUP_CONCAT( keywords.name ) 
        FROM candidate_group_keywords LEFT OUTER JOIN keywords ON ( keywords.id = candidate_group_keywords.keyword_id ) GROUP BY candidate_group_keywords.group_id' )
  end
  
  #
  # Populate story_groups table and story_group_memberships from final groups
  #
  def populate_story_groups_table_from_final_groups
    
    @final_groups = db.select_all( '
      SELECT candidate_groups.id AS pilot_story_id, 
        candidate_groups.language_id,
        COALESCE( GROUP_CONCAT( category_id ), "" ) AS category_ids,
        candidate_group_top_keywords.keywords AS top_keywords,
        COUNT(*) AS story_count, 
        COUNT(DISTINCT source_id) AS source_count,
        SUM(is_video = ' + db.quoted_true + ') AS video_count,
        SUM(is_opinion = ' + db.quoted_true + ') AS opinion_count,
        SUM(is_blog = ' + db.quoted_true + ') AS blog_count,
        MAX(thumbnail_exists) AS thumbnail_exists
      FROM candidate_groups
      LEFT OUTER JOIN candidate_group_top_keywords ON ( candidate_group_top_keywords.id = candidate_groups.id )
      INNER JOIN candidate_group_stories ON ( candidate_group_stories.group_id = candidate_groups.id AND candidate_group_stories.master_id IS NULL)
      GROUP BY candidate_groups.id HAVING source_count > 1 AND story_count > 1' )
    
    # Fetch all stories and group them by group_id
    @group_stories = db.select_all( 'SELECT group_id, story_id, thumbnail_exists, source_id, created_at, quality_rating, blub_score, master_id, rank 
      FROM candidate_group_stories ORDER BY group_id, blub_score' ).group_by{ |x| x['group_id'].to_i }
    
    # Fetch all pilot stories group by pilot_story_id
    #pilot_story_ids = db.select_values('SELECT id FROM candidate_groups')
    #@pilot_stories = master_db.select_all( 'SELECT story_id, body FROM story_contents 
    #  WHERE story_id IN (' + pilot_story_ids.join(',') + ')' ).group_by{ |x| x['story_id'].to_i }
    #pilot_story_ids = nil
    
    #StoryGroup.transaction do
      @final_groups.each do | group_attributes |
        
        category_ids = group_attributes.delete( 'category_ids' ).to_s.split(',').collect!{ |x| x.to_i }
        
        top_keywords = group_attributes.delete( 'top_keywords' ).to_s.split(',')
        
        StoryGroup.create( group_attributes ) do | group |
          
          # Getting the top category id
          group.category_id = Category.top_category_id( category_ids )
          
          # Getting the top 3 keywords
          group.top_keywords = top_keywords #JCore::Keyword.words( @pilot_stories[ group.pilot_story_id ].first[ 'body' ], top_keywords )
          #group.top_keywords += top_keywords unless top_keywords.empty?
          
          # Setting the session id
          group.bj_session_id = @session.id
          
          # Setting the broadness score
          group.broadness_score = group.source_count + group.story_count / 100.00
          
          # Setting up group memberships
          db_true_value = db.quoted_true.gsub('\'', '')
          @group_stories[ group.pilot_story_id ].each{ |story_attributes|
            
            story_attributes.delete('group_id')
            
            # Setting the group thumbnail story id ( if required )
            group.thumbnail_story_id = story_attributes['story_id'] if ( story_attributes.delete('thumbnail_exists') == db_true_value && 
              group.thumbnail_exists? && group.thumbnail_story_id.nil? )
            
            group.memberships << StoryGroupMembership.new( story_attributes.merge!( :bj_session_id => @session.id ) )
          }
        end
      #end
    end
    
    @pilot_stories = []
    @group_stories = []
    @final_groups = []
    
  end
  
  def archive_old_groups
    
    session_ids = @session.id.to_s
    
    master_db.execute( MasterDB::Insert::Ignore + 'INTO story_group_membership_archives (
        bj_session_id, group_id, story_id, source_id, created_at, quality_rating, blub_score, master_id
      ) SELECT bj_session_id, group_id, story_id, source_id, created_at, quality_rating, blub_score, master_id
      FROM story_group_memberships WHERE bj_session_id NOT IN ('+ session_ids +')')
    
    master_db.execute( 'DELETE FROM story_group_memberships WHERE bj_session_id NOT IN ('+ session_ids + ')' )
    # more_entries = true
    # while more_entries
    #   more_entries = false
    #   StoryGroupMembership.find( :all, :conditions => "bj_session_id NOT IN ( #{session_ids} )", :limit => 1000 ).each do |sgm|
    #     sgm.destroy
    #     more_entries ||= true
    #   end
    # end
    master_db.execute( MasterDB::Insert::Ignore + 'INTO story_group_archives ( 
        group_id, bj_session_id, pilot_story_id, category_id, 
        language_id, top_keywords, story_count, source_count, 
        video_count, blog_count, opinion_count, broadness_score, 
        created_at ) 
      SELECT id, bj_session_id, pilot_story_id, category_id, 
        language_id, top_keywords, story_count, source_count, video_count,
        blog_count, opinion_count, broadness_score, created_at
      FROM story_groups WHERE bj_session_id NOT IN (' + session_ids + ')' )
    
    master_db.execute( 'DELETE FROM story_groups WHERE bj_session_id NOT IN (' + session_ids + ')' )
    
    # LIMITING THE STORY GROUP ARCHIVES
    target = BjSession.find(:first, :conditions => [ 'created_at < ?', 24.hours.ago ], :order => 'created_at DESC')
    min = StoryGroupArchive.minimum( :bj_session_id )
    if target && target.id >= min
      StoryGroupArchive.delete_all( "bj_session_id < #{target.id}" )
      StoryGroupMembershipArchive.delete_all( "bj_session_id < #{target.id}" )
    end
  end
  
  def cluster_group_mappings
    ClusterGroup.find_each do |cluster_group|
      ClusterGroupMembership.update_all( 'flagged=true', { :cluster_group_id => cluster_group.id } )
      StoryGroup.by_session( @session ).find_each_for_cluster_group( cluster_group ) do |story_group|
        cluster_group.memberships.create(  :flagged => false, :active => false, :story_group_id => story_group.id, :broadness_score => story_group.broadness_score )
      end
      rank = 1
      offset = 0
      loop do
        cluster_group_memberships = ClusterGroupMembership.all( :conditions => { :cluster_group_id => cluster_group.id, :active => false }, 
          :order => 'broadness_score DESC', :limit => 1000, :offset => offset )
        break if cluster_group_memberships.empty?
        cluster_group_memberships.each do |cluster_group_membership|
          cluster_group_membership.update_attribute( :rank, rank )
          rank += 1
        end
        offset += 1000
        cluster_group_memberships.clear
      end
    end
    ClusterGroupMembership.update_all( 'active=true', { :active => false } )
    @session.update_attributes( :running => false )
    ClusterGroupMembership.delete_all( { :flagged => true } )
  end

end
