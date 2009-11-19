class StoryGroupMembership < ActiveRecord::Base
  
  belongs_to :story
  belongs_to :story_group, :class_name => 'StoryGroup', :foreign_key => :group_id
  
end