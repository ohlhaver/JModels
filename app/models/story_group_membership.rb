class StoryGroupMembership < ActiveRecord::Base

  
  class Active < ActiveRecord::Base
    
    set_table_name :active_story_group_memberships
    set_primary_keys :story_id, :group_id
    
    belongs_to :story
    belongs_to :story_group, :class_name => 'StoryGroup', :foreign_key => :group_id
    
  end
  
  set_primary_keys :group_id, :story_id
  
  belongs_to :story
  belongs_to :story_group, :class_name => 'StoryGroup', :foreign_key => :group_id
  before_create :check_for_story
  
  protected
  
  def check_for_story
    Story.exists?( self.story_id )
  end
end