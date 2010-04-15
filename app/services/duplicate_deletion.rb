# Deletes Duplicates within a particular source
class DuplicateDeletion < BackgroundService
  
  def start( options = {} )
    delete_duplicates_within_source( options )
    mark_duplicates_across_source( options )
  end
  
  def finalize( options = {} )
  end
  
  protected
  
  def mark_duplicates_across_source( options )
    @duplicates_found = 0
    duplicate_titles = db.select_values( 'SELECT GROUP_CONCAT(id) FROM candidate_stories WHERE master_id IS NULL GROUP BY title_hash ASC HAVING COUNT(*) > 1' )
    duplicate_titles.each do |story_ids|
      break if exit?
      # if two strings are same there hash value will be same but not vice versa
      # therefore title hash match do have false positives
      # select stories and group them by titles
      duplicate_stories = master_db.select_all( 'SELECT id, title FROM stories WHERE id IN (' + story_ids + ') ORDER BY created_at ASC').group_by{ |story| story['title'] }
      duplicate_stories.each do | title, stories |
        next if stories.size < 2
        mark_duplicates( stories.collect{ |x| x['id'] } )
        stories.clear
      end
      duplicate_stories.clear
    end
    duplicate_titles.clear
    logger.info( 'Duplicates Marked: ' + @duplicates_found.to_s )
  end
  
  def mark_duplicates( story_ids )
    master_id = story_ids.shift
    master_story_metric = StoryMetric.find( :first, :conditions => { :story_id => master_id } )
    if master_story_metric.try(:master_id)
      story_ids.unshift( master_id )
      master_id = master_story_metric.master_id
      story_ids.delete( master_id )
    end
    db.execute( "UPDATE candidate_stories 
      SET master_id = #{master_id} WHERE id IN ( #{story_ids.join(',')} )" )
    story_ids.each do |story_id|
      StoryMetric.create_or_update( :story_id => story_id, :master_id => master_id )
      @duplicates_found += 1
    end
  end
  
  def delete_duplicates_within_source( options )
    @duplicates_found = 0
    duplicate_titles = db.select_values( 'SELECT GROUP_CONCAT(id) FROM candidate_stories GROUP BY title_hash, source_id HAVING COUNT(*) > 1' )
    duplicate_titles.each do |story_ids|
      break if exit?
      # if two strings are same there hash value will be same but not vice versa
      # therefore title hash match do have false positives
      # select stories and group them by titles
      duplicate_stories = master_db.select_all( 'SELECT id, title FROM stories WHERE id IN (' + story_ids + ')').group_by{ |story| story['title'] }
      duplicate_stories.each do | title, stories |
        next if stories.size < 2
        remove_duplicate_titles_from( stories.collect{ |x| x['id'] } )
        stories.clear
      end
      duplicate_stories.clear
    end
    duplicate_titles.clear
    logger.info( 'Duplicates Deleted: ' + @duplicates_found.to_s )
  end
  
  def remove_duplicate_titles_from( story_ids )
    stories = ( Story.find( story_ids ) rescue [] )
    return if stories.blank?
    master_story_id = db.select_value( 'SELECT id FROM candidate_stories WHERE id IN (' + db.quote_and_merge( *story_ids ) + 
        ') AND category_id IS NOT NULL ORDER BY category_id LIMIT 1' )
    master_story = nil
    stories.delete_if{ |story| 
      if story.id == master_story_id.to_i then master_story = story; true
      else false end
    } if master_story_id
    master_story ||= stories.pop
    master_story.is_blog = stories.inject( master_story.is_blog ){ |s,x| s = s || x.is_blog }
    master_story.is_video = stories.inject( master_story.is_video ){ |s,x| s = s || x.is_video }
    master_story.is_opinion = stories.inject( master_story.is_opinion ){ |s,x| s = s || x.is_opinion }
    master_story.story_metric.update_attributes( :master_id => nil ) if master_story.story_metric
    master_story.save if master_story.changed?
    delete_stories_from_background_db(  *( stories.collect{ |x| x.id } ) )
    db.execute( 'UPDATE candidate_stories SET is_blog = ' + db.quote( master_story.is_blog ) + ', is_video = ' + db.quote( master_story.is_video ) +
      ', is_opinion = ' + db.quote( master_story.is_opinion ) + ' WHERE id = ' + db.quote( master_story.id ) )
    stories.each{ |story| story.destroy }
    @duplicates_found += stories.size
    stories.clear
    #logger.info( 'Deleted Duplicate Story: ' + stories.collect{ |x| x.id }.to_s )
  end
  
  def delete_stories_from_background_db( *story_ids )
    quoted_story_ids = db.quote_and_merge( *story_ids )
    db.execute( 'DELETE FROM candidate_similarities WHERE story1_id IN (' + quoted_story_ids + ')' )
    db.execute( 'DELETE FROM candidate_similarities WHERE story2_id IN (' + quoted_story_ids + ')' )
    db.execute( 'DELETE FROM candidate_group_similarities WHERE story1_id IN (' + quoted_story_ids + ')' )
    db.execute( 'DELETE FROM candidate_group_similarities WHERE story2_id IN (' + quoted_story_ids + ')' )
    db.execute( 'DELETE FROM keyword_subscriptions WHERE story_id IN (' + quoted_story_ids + ')' )
    db.execute( 'DELETE FROM candidate_stories WHERE id IN (' + quoted_story_ids + ')' )
  end
  
end