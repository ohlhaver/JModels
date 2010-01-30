class CorrectColumnType < ActiveRecord::Migration
  def self.up
    remove_column :story_group_memberships, :created_at
    add_column :story_group_memberships, :created_at, :timestamp
    execute( 'UPDATE story_group_memberships LEFT OUTER JOIN stories ON ( stories.id = story_group_memberships.story_id) SET story_group_memberships.created_at = stories.created_at' )
    remove_column :story_group_membership_archives, :created_at
    add_column :story_group_membership_archives, :created_at, :timestamp
    execute( 'UPDATE story_group_membership_archives LEFT OUTER JOIN stories ON ( stories.id = story_group_membership_archives.story_id) SET story_group_membership_archives.created_at = stories.created_at' )
  end

  def self.down
  end
end
