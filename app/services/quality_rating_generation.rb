class QualityRatingGeneration < BackgroundService
  
  def start( options = {} )
    return incremental if options[:incremental]
    overall
  end
  
  def finalize( options = {} )
  end
  
  protected
  
  def incremental
    Story.find_each( :conditions => { :quality_ratings_generated => false }, :include => [ :authors, :source ] ) do |story|
      process_story( story )
      break if parent && parent.respond_to?( :exit? ) && parent.send( :exit? )
    end
  end
  
  def overall
    # Mapping of all stories less than 1 month old are removed
    StoryUserQualityRating.delete_all( 'created_at < DATE_SUB( UTC_TIMESTAMP(), INTERVAL 1 MONTH )' )
    # Mappings of all stories from last 1 month are remapped according to Users Preferences
    Story.find_each( :conditions => 'created_at >= DATE_SUB( UTC_TIMESTAMP(), INTERVAL 1 MONTH )', :include => [ :authors, :source, :story_metric ] ) do |story|
      process_story( story )
      break if parent && parent.respond_to?( :exit? ) && parent.send( :exit? )
    end
  end
  
  def process_story( story )
    
    user_ids = {}
    author_quality_ratings_sum = 0
    author_quality_ratings_count = 0
    
    AuthorSubscription.find_each( :group => 'owner_id', 
      :select => 'author_subscriptions.*, MAX( IF(subscribed, COALESCE(author_subscriptions.preference,3), author_subscriptions.preference ) ) AS preference', 
      :conditions => { :author_id => story.author_ids, :owner_type => 'User' } 
    ) do |author_subscription|
      next if author_subscription.preference.nil?
      StoryUserQualityRating.create( :source => false, :preference => author_subscription.preference, 
        :user_id => author_subscription.owner_id, :created_at => story.created_at, :story_id => story.id,
        :quality_rating => author_subscription.preference )
      author_quality_ratings_sum += author_subscription.preference
      author_quality_ratings_count += 1
      user_ids[ author_subscription.owner_id ] = true
    end
    
    unless story.quality_ratings_generated?
      story.author_quality_rating = ( author_quality_ratings_count < 10 ?  nil : ( author_quality_ratings_sum.to_f / author_quality_ratings_count ) )
    end
    
    source_quality_ratings_sum = 0
    source_quality_ratings_count = 0
    SourceSubscription.find_each( 
      :conditions => { :source_id => story.source_id, :category_id => nil, :owner_type => 'User' }
    ) do |source_subscription|
      next if source_subscription.preference.nil? || user_ids.has_key?( source_subscription.owner_id )
      user_quality_rating = ( source_subscription.preference > 0 && story.author_quality_rating ) ? ( source_subscription.preference + story.author_quality_rating ) / 2.0 : source_subscription.preference
      StoryUserQualityRating.create( :source => true, :preference => source_subscription.preference, 
        :user_id => source_subscription.owner_id, :created_at => story.created_at, :story_id => story.id, :quality_rating => user_quality_rating )
      source_quality_ratings_sum += source_subscription.preference
      source_quality_ratings_count += 1
      user_ids[ source_subscription.owner_id ] = true
    end
    
    # To be delete user quality ratings
    StoryUserQualityRating.all( :select => 'user_id, story_id', :conditions => { :story_id => story.id } ).each do | quality_rating |
      next if user_ids.has_key?( quality_rating.user_id )
      quality_rating.destroy
    end if story.quality_ratings_generated?
    
    user_ids.clear
    
    # These are generated once when used in incremental format
    unless story.quality_ratings_generated?
      story.source_quality_rating = ( source_quality_ratings_count < 10 ?  story.source.try(:default_preference) : ( source_quality_ratings_sum.to_f / source_quality_ratings_count ) )
      story.quality_rating = story.author_quality_rating || story.source_quality_rating || 1
      story.quality_ratings_generated ||= true
      delete_useless_records( story )
      story.save if story.changed?
    else
      delete_useless_records( story )
    end
    
  end
  
  def delete_useless_records( story )
    return unless story.quality_rating
    StoryUserQualityRating.delete_all( :story_id => story.id, :quality_rating => story.quality_rating )
  end
  
end