class StoryContent < ActiveRecord::Base
  
  set_primary_key :story_id
  
  belongs_to :story
  
  after_save :set_story_delta_flag
  after_destroy :set_story_delta_flag
  
  def set_story_delta_flag
    story.update_attribute( :delta, true )
  end
  
end
