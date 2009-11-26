class StoryGroupMembershipsMasterId < ActiveRecord::Migration
  
  def self.up
    add_column :story_group_memberships, :master_id, :integer
  end
  
  def self.down
    remove_column :story_group_memberships, :master_id
  end
  
end