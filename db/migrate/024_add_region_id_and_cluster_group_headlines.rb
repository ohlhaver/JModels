class AddRegionIdAndClusterGroupHeadlines < ActiveRecord::Migration
  
  def self.up
    add_column :preferences, :region_id, :integer
    add_column :preferences, :headlines_per_cluster_group, :integer
  end
  
  def self.down
    remove_column :preferences, :region_id
    remove_column :preferences, :headlines_per_cluster_group
  end
  
end