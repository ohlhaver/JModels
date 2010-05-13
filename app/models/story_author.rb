class StoryAuthor < ActiveRecord::Base
  belongs_to  :story
  belongs_to  :author
  
  before_create :set_block_column
  before_save :set_delta_index_story
  after_save :set_story_delta_flag
  after_destroy :set_story_delta_flag
  
  set_primary_keys :story_id, :author_id
  
  protected
  
  def set_block_column
    self.block = self.author.block
    return true
  end
  
  def set_delta_index_story
    @delta_index_story = author_id_changed?
    return true
  end
  
  def set_story_delta_flag
    story.update_attribute( :delta, true ) if frozen? || @delta_index_story
  end
  
end