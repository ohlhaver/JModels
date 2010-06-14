class StoryTitle < ActiveRecord::Base
  
  set_primary_key :story_id
  attr_accessible :story_id, :title, :source_id, :wip
  
  before_create :normalize_title
  
  def self.bootstrap!
    story_ids = Array.new
    Story.find_each( :select => 'id, source_id, title', 
      :conditions => ['duplicate_checked = ? AND created_at < ?', false, 24.hours.ago ] ) do |story| 
      create_from_story( story )
      story_ids << story.id
      unless story_ids.size < 1000
        Story.update_all( { :duplicate_checked => true}, { :id => story_ids } )
        logger.info( "Story Title Bootstrap: 1000 stories pushed. [#{Time.now.utc.to_s(:db)}]")
        story_ids.clear
      end
    end
    Story.update_all( { :duplicate_checked => true }, { :id => story_ids } ) unless story_ids.blank?
  end
  
  def self.create_from_story( story )
    s = new do |t| 
      t.story_id = story.id
      t.source_id = story.source_id
      t.title = story.title
      t.wip = 0
    end
    s.save
    return s
  end
  
  # Keep the story_titles records for last 5.days for the duplicates
  def self.purge!
    connection.execute( "DELETE FROM story_titles WHERE story_id IN ( SELECT id FROM stories WHERE created_at >= '#{5.days.ago.to_s(:db)}')" )
  end
  
  protected
  
  def normalize_title
    self.title = title.mb_chars.downcase.gsub(/\s+/,'_').gsub(/\W+/,'').to_s
  end
  
end
