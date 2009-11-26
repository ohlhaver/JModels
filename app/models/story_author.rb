class StoryAuthor < ActiveRecord::Base
  belongs_to  :story
  belongs_to  :author
  
  before_save :set_story_delta_flag
  after_save :set_story_delta_flag
  after_destroy :set_story_delta_flag
  
  def set_story_delta_flag
    story.update_attribute( :delta, true ) if frozen? || @delta_index_story
  end
  
end
