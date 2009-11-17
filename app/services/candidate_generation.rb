#
# Generates a pool of stories on which algorithms should run
# Creates a candidate_stories table with stories from last 24 hours
#
class CandidateGeneration < BackgroundService
  
  def start( options = {} )
    options ||= {}
    time = options[:time] || Time.now.utc
    
    db.create_table( 'candidate_stories', :force => true ) do |t|
      t.integer :master_id
      t.integer :language_id
      t.integer :source_id
      t.integer :category_id
      t.boolean :is_video
      t.boolean :is_blog
      t.boolean :is_opinion
      t.boolean :keyword_exists
      t.datetime :created_at
    end
    
    time += -24.hours
    
    # Candidate Stories are last 24 hours stories
    db.execute( 'INSERT INTO candidate_stories ( id, language_id, source_id, category_id, is_video, is_blog, is_opinion, created_at, master_id, keyword_exists )
      SELECT stories.id, stories.language_id, stories.source_id, MAX( feed_categories.category_id ), stories.is_video, stories.is_blog, stories.is_opinion, stories.created_at,
      story_metrics.master_id, COALESCE( story_metrics.keyword_exists, ' + db.quoted_false + ')
      FROM stories LEFT OUTER JOIN feed_categories ON ( feed_categories.feed_id = stories.feed_id )
      LEFT OUTER JOIN story_metrics ON ( story_metrics.story_id = stories.id ) WHERE created_at >= ' + time.to_s(:db).dump + ' GROUP BY stories.id')
      
    # Also get stories which are the duplicates that algorithm found out and are not in the candidate stories
    db.execute( ' INSERT OR IGNORE INTO candidate_stories ( id, master_id, keyword_exists )
      SELECT story_metrics.story_id, story_metrics.master_id, story_metrics.keyword_exists 
      FROM story_metrics WHERE story_metrics.master_id IN ( SELECT candidate_stories.master_id FROM candidate_stories GROUP BY candidate_stories.master_id ) ')
    
    # Generate keywords for the stories which do not have the keywords
    Story.find_each( :joins => 'INNER JOIN candidate_stories ON ( candidate_stories.id = stories.id )', 
      :conditions => [ 'candidate_stories.keyword_exists = ? ', false ], :include => :story_metric ) do | story |
      Keyword.save( story )
    end
    db.execute( 'UPDATE candidate_stories SET keyword_exists = 1' )
  end
  
  def finalize( optoins = {} )
    db.drop_table( 'candidate_stories' )
  end
  
end