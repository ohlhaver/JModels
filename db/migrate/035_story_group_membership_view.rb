class StoryGroupMembershipView < ActiveRecord::Migration
  
  def self.up
    execute %Q(
      CREATE VIEW active_story_group_memberships AS SELECT 
        story_id, MAX( group_id ) as group_id
      FROM story_group_memberships GROUP BY story_id;
    )
  end
  
  def self.down
    execute %Q(
      DROP VIEW active_story_group_memberships
    )
  end
  
end