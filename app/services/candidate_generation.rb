#
# Generates a pool of stories on which algorithms should run
# Creates a candidate_stories table with stories from last 24 hours
#
#require 'ruby-debug'
class CandidateGeneration < BackgroundService
  
  def initialize( options = {} )
    super(options)
    @keyword_caches = Hash.new{ |h,k| h[k] = ActiveSupport::Cache::MemoryStore.new }
    @story_titles = Hash.new
    @story_languages = Hash.new
  end
  
  def start( options = {} )
    sync_recent_stories( options[:time] || Time.now.utc )
  end
  
  def finalize( options = {} )
  end
  
  def clear_all!
    clear_cache!
    db.execute('DELETE FROM keyword_subscriptions')
    db.execute('DELETE FROM keywords' )
    db.execute('DELETE FROM candidate_stories')
    db.execute('DELETE FROM candidate_similarities')
    db.execute('DELETE FROM candidate_group_similarities')
  end
  
  def clear_cache!
    @keyword_caches.each{ |k,v| v.clear }
  end
  
  protected
  
  def sync_recent_stories( time )
    
    last_story_found_at = db.select_value('SELECT MAX(created_at) FROM candidate_stories').try(:to_time)
    
    if last_story_found_at.nil? || last_story_found_at < 24.hours.ago( time )
      last_story_found_at = 24.hours.ago( time )
    else
      last_story_found_at -= 5.minutes # 5.minutes backlog
    end
    
    attributes = [ :id, :title_hash, :language_id, :source_id, :category_id, :is_video, :is_blog, :is_opinion, :thumbnail_exists, :quality_rating, :master_id, :created_at, :keyword_exists ]
    
    attributes_to_select = Story.select_attributes( :id, :title, :language_id, :source_id, 'MAX(feed_categories.category_id) AS category_id', 
      :is_video, :is_blog, :is_opinion, :thumbnail_exists, 'COALESCE( stories.quality_rating, 1) AS quality_rating', 'story_metrics.master_id', :created_at, 
      'languages.code AS language_code', "#{db.quoted_false} AS keyword_exists" )
      
    column_names = attributes.join(', ')
    new_stories_count = 0
    
    db.transaction do
      
      Story.find_in_batches( :select => attributes_to_select, :joins => 'LEFT OUTER JOIN feed_categories ON ( feed_categories.feed_id = stories.feed_id ) 
          LEFT OUTER JOIN story_metrics ON ( story_metrics.story_id = stories.id ) LEFT OUTER JOIN languages ON ( languages.id = stories.language_id)', 
        :conditions => [ 'created_at >= ? ', last_story_found_at ], :group => 'stories.id' ) do |story_batch|
        
        story_batch.each do |story|
          @story_titles[ story.id ] = story.title
          # storing title hash for duplicate deletion within a source
          story.send(:write_attribute, :title_hash, story.title.hash )
          @story_languages[ story.id ] = { :code => story.send( :read_attribute, :language_code ), :id => story.language_id }
          db.execute( DB::Insert::Ignore + 'INTO candidate_stories ( ' +  column_names + ') VALUES(' + story.to_csv( *attributes ) + ')' )
        end
        new_stories_count += db.select_value('SELECT COUNT(*) FROM candidate_stories WHERE keyword_exists = ' + db.quoted_false ).to_i
        generate_keywords_for_stories
        
        @story_titles.clear
        @story_languages.clear
      end
      
      clear_cache!
      clear_old_stories( 24.hours.ago( time ) - 5.minutes ) # Delete stories older then 24 hours ago from now 
      
    end
    logger.info( 'New Candidates Stories Count: ' + new_stories_count.to_s )
    logger.info( 'Total Candidate Stories Count: ' + db.select_value( 'SELECT COUNT(*) FROM candidate_stories' ) )
  end
  
  def clear_old_stories( time )
    db.execute('DELETE FROM keyword_subscriptions WHERE story_id IN ( SELECT candidate_stories.id FROM candidate_stories WHERE created_at < '+ db.quote( time ) +')')
    db.execute('DELETE FROM candidate_similarities WHERE story1_id IN ( SELECT candidate_stories.id FROM candidate_stories WHERE created_at < '+ db.quote( time ) +')')
    db.execute('DELETE FROM candidate_similarities WHERE story2_id IN ( SELECT candidate_stories.id FROM candidate_stories WHERE created_at < '+ db.quote( time ) +')')
    db.execute('DELETE FROM candidate_group_similarities WHERE story1_id IN ( SELECT candidate_stories.id FROM candidate_stories WHERE created_at < '+ db.quote( time ) +')')
    db.execute('DELETE FROM candidate_group_similarities WHERE story2_id IN ( SELECT candidate_stories.id FROM candidate_stories WHERE created_at < '+ db.quote( time ) +')')
    db.execute('DELETE FROM candidate_stories WHERE created_at < ' + db.quote( time ))
  end
  
  def generate_keywords_for_stories
    loop do
      story_ids = db.select_values( 'SELECT id FROM candidate_stories WHERE keyword_exists = ' + db.quoted_false + ' LIMIT 100' )
      break if story_ids.empty?
      StoryContent.find(:all, :conditions => { :story_id => story_ids }).each{ |story_content|
        language_code =  @story_languages[ story_content.story_id ][:code].to_s
        language_id = @story_languages[ story_content.story_id ][:id].to_s
        keywords = JCore::Keyword.collection( @story_titles[ story_content.story_id ] + ' ' + story_content.body, language_code )
        keywords.each do |keyword|
          keyword_id = get_keyword_id( keyword, language_id )
          db.execute( DB::Insert::Ignore + 'INTO keyword_subscriptions ( keyword_id, story_id, frequency, excerpt_frequency) 
            VALUES(' + db.quote_and_merge( keyword_id, story_content.story_id, keywords.rank( keyword ), keywords.rank( keyword, :selected ) )  + ')')
        end
      }
      db.execute( 'UPDATE candidate_stories SET keyword_exists = ' + db.quoted_true + ' WHERE id IN (' + story_ids.join(',') + ')')
    end
  end
  
  #
  # Gets the Keyword from the Cache or Insert the item into the Keywords Table and update the Cache
  #
  def get_keyword_id( keyword, language_id )
    keyword_id = @keyword_caches[ language_id.to_i ].read( keyword )
    return keyword_id if keyword_id # Value In Cache
    quoted_values = db.quote_all( keyword, language_id )
    db.execute( DB::Insert::Ignore + 'INTO keywords (name, language_id) VALUES(' + quoted_values.join(',') + ')' )
    keyword_id = db.select_value( "SELECT id FROM keywords WHERE language_id = #{quoted_values[1]} AND name = #{quoted_values[0]}" ).to_i
    @keyword_caches[ language_id.to_i ].write( keyword, keyword_id )
  end
  
end