class StoryMetric < ActiveRecord::Base
  
  belongs_to :story
  
  before_save :set_delta_index_story
  after_save :set_story_delta_flag
  after_destroy :set_story_delta_flag
  
  def set_delta_index_story
    @delta_index_story = master_id_changed?
  end
  
  def set_story_delta_flag
    story.update_attribute( :delta, true ) if frozen? || @delta_index_story
  end
  
end