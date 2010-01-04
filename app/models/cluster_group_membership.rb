class ClusterGroupMembership < ActiveRecord::Base
  
  set_primary_keys :cluster_group_id, :story_group_id
  
  belongs_to :story_group
  belongs_to :cluster_group
  
end
