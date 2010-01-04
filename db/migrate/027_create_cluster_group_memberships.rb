class CreateClusterGroupMemberships < ActiveRecord::Migration
  def self.up
    create_table :cluster_group_memberships, :id => false do |t|
      t.integer :cluster_group_id
      t.integer :story_group_id
      t.float   :broadness_score
      t.integer :rank
      t.boolean :active, :default => false, :null => false
      t.boolean :flagged, :default => false, :null => false
    end
    add_index :cluster_group_memberships, [ :cluster_group_id, :story_group_id ], :unique => true, :name => 'cluster_group_memberships_unique_idx'
    add_index :cluster_group_memberships, [ :cluster_group_id, :active, :story_group_id ], :unique => true, :name => 'cluster_group_memberships_active_unique_idx'
    
    add_column :story_group_memberships, :rank, :integer
  end

  def self.down
    drop_table :cluster_group_memberships
    remove_column :story_group_memberships, :rank
  end
end
