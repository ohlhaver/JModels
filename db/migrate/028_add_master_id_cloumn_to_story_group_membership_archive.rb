class AddMasterIdCloumnToStoryGroupMembershipArchive < ActiveRecord::Migration
  def self.up
    add_column :story_group_membership_archives, :master_id, :integer
  end

  def self.down
    remove_column :story_group_membership_archives, :master_id
  end
end
