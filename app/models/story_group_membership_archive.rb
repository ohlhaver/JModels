class StoryGroupMembershipArchive < ActiveRecord::Base
  
  set_primary_keys :group_id, :story_id
  
  belongs_to :story
  belongs_to :story_group_archive, :foreign_key => :group_id
  
end