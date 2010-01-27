class StoryGroupMembership < ActiveRecord::Base
  
  set_primary_keys :group_id, :story_id
  
  belongs_to :story
  belongs_to :story_group, :class_name => 'StoryGroup', :foreign_key => :group_id
  
  #after_create  :set_story_delta_flag
  #after_destroy :set_story_delta_flag
  
  protected
    
  #def set_story_delta_flag
  #  story.update_attribute( :delta, true ) if frozen?
  #end
  
end