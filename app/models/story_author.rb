class StoryAuthor < ActiveRecord::Base
  belongs_to  :story
  belongs_to  :author
  
  before_create :set_block_column, :set_story_created_at_column
  before_save :set_delta_index_story
  after_save :set_story_delta_flag
  after_destroy :set_story_delta_flag
  
  set_primary_keys :story_id, :author_id
  
  def self.each_story( &block )
    more_records = true
    while( more_records )
      records = StoryAuthor.find( :all, :select => 'DISTINCT story_id', :conditions => { :story_created_at => nil }, :limit => 1001, :include => :story )
      more_records = records.size > 1000 ? records.pop : nil
      records.each{ |record| block.call( record.story, record.story_id ) }
    end
  end
  
  protected
  
  def set_block_column
    self.block = self.author.block
    return true
  end
  
  def set_story_created_at_column
    self.story_created_at = self.story.created_at
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