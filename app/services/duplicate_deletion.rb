# Deletes Duplicates within a particular source
class DuplicateDeletion < BackgroundService
  
  def start( options = {} )
    prepare_for_duplicate_deletion
    delete_duplicates_within_source( options )
    mark_duplicates_across_source( options )
  end
  
  def finalize( options = {} )
    Story.update_all( { :duplicate_checked => true }, { :id => @checked_story_ids, :duplicate_checked => false } )
    StoryTitle.update_all( {:wip => 0 }, { :wip => 1 } )
    @checked_story_ids.clear
  end
  
  protected
  
  def prepare_for_duplicate_deletion
    @checked_story_ids = []
    stories = Story.find(:all, :select => 'id, title, source_id', :conditions => { :duplicate_checked => false }, :limit => 1000)
    stories.each do |story|
      begin
        story_title = StoryTitle.create_from_story( story )
      rescue StandardError
        mark_checked( story.id )
      end
      StoryTitle.update_all( { :wip => 1 }, { :wip => 0, :title => story_title.title } )
    end
    stories.clear
  end
  
  def mark_duplicates_across_source( options )
    duplicate_titles = StoryTitle.find(:all, :select => 'GROUP_CONCAT( story_id ) AS story_ids', :conditions => { :wip => true }, 
        :group => 'title', :having => 'COUNT(*) > 1')
    count = 0
    duplicate_titles.each do |duplicate_title|
      story_ids = duplicate_title.send( :read_attribute, :story_ids ).split(',')
      count += mark_duplicates( story_ids )
    end
    duplicate_titles.clear
    logger.info( 'Duplicates Marked: ' + count.to_s )
  end
  
  def mark_duplicates( story_ids )
    mark_checked( story_ids )
    story_ids.collect!( &:to_i )
    master_story = Story.find(:first, :select => 'id', :conditions => { :id => story_ids }, :order => 'created_at ASC', :include => :story_metric )
    master_id = master_story.story_metric.try(:master_id) ? master_story.story_metric.master_id : master_story.id
    story_ids.delete( master_id )
    story_ids.each do |story_id|
      StoryMetric.create_or_update( :story_id => story_id, :master_id => master_id )
    end
    story_ids.size
  end
  
  def delete_duplicates_within_source( options )
    stories_to_purge = []
    duplicate_titles = StoryTitle.find(:all, :select => 'GROUP_CONCAT( story_id ) AS story_ids', :conditions => { :wip => true }, 
      :group => 'source_id, title', :having => 'COUNT(*) > 1')
    duplicate_titles.each do |duplicate_title|
      story_ids = duplicate_title.send( :read_attribute, :story_ids ).split(',')
      remove_duplicate_titles_from( story_ids ).inject( stories_to_purge ){ |s,x| s.push(x) }
    end
    Story.purge_without_sphinx_callbacks!( stories_to_purge )
    logger.info( 'Duplicates Deleted: ' + stories_to_purge.size.to_s )
    stories_to_purge.clear
  end
  
  def remove_duplicate_titles_from( story_ids )
    stories = Story.find( :all, :select => 'id, feed_id, is_blog, is_video, is_opinion', :conditions => { :id => story_ids }, :order => 'created_at DESC', :include => { :feed => :categories } )
    return stories if stories.blank?
    master_story = stories.pop
    category_id = master_story.feed.try( :category_id )
    unless category_id
      category_story = stories.select{ |x| !x.feed.try( :category_id ).nil? }.first
      if category_story
        master_story.feed_id = category_story.feed_id
        category_id = category_story.feed.try( :category_id )
      end
    end
    master_story.is_blog = stories.inject( master_story.is_blog ){ |s,x| s = s || x.is_blog } unless master_story.is_blog?
    master_story.is_video = stories.inject( master_story.is_video ){ |s,x| s = s || x.is_video } unless master_story.is_video?
    master_story.is_opinion = stories.inject( master_story.is_opinion ){ |s,x| s = s || x.is_opinion } unless master_story.is_opinion?
    mark_checked( master_story.id )
    if master_story.changed?
      master_story.save
      db.execute( 'UPDATE candidate_stories SET is_blog = ' + db.quote( master_story.is_blog ) + ', is_video = ' + db.quote( master_story.is_video ) +
        ', is_opinion = ' + db.quote( master_story.is_opinion ) + ', category_id = ' + db.quote( category_id ) + ' WHERE id = ' + db.quote( master_story.id ) )
    end
    stories
  end
  
  def mark_checked( story_ids_or_array )
    Array( story_ids_or_array ).inject( @checked_story_ids ){ |s,x| s.push( x ) }
  end
  
end