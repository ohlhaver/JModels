class StoryTitle < ActiveRecord::Base
  
  set_primary_key :story_id
  attr_accessible :story_id, :title, :source_id, :wip
  
  before_create :normalize_title
  
  def self.bootstrap!
    Story.update_all( { :duplicate_checked => true }, [ 'created_at < ?', 24.hours.ago ] )
    Story.find_each( :select => 'id, source_id, title', :conditions => { :duplicate_checked => true } ){ |story| create_from_story( story ) }
  end
  
  def self.create_from_story( story )
    new do |t| 
      t.story_id = story.id
      t.source_id = story.source_id
      t.title = story.title
      t.wip = 0
    end.save
  end
  
  protected
  
  def normalize_title
    self.title = title.mb_chars.downcase.gsub(/\s+/,'_').gsub(/\W+/,'').to_s
  end
  
end
