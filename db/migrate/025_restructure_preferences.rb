class RestructurePreferences < ActiveRecord::Migration
  
  def self.up
    remove_index "cluster_groups", :name => "index_cluster_groups_on_owner_type_and_owner_id_and_name"
    add_index "cluster_groups", ["owner_type", "owner_id", "perspective_type", "perspective_id", "language_id", "name"], 
        :name => "index_cluster_groups_unique", :unique => true
    add_column "multi_valued_preferences", "tag", :string, :default => "0"
    remove_index "multi_valued_preferences", :name => "multi_valued_preferences_position_idx"
    add_index "multi_valued_preferences", [ "owner_type", "owner_id", "preference_id", "tag", "position", "value" ], :name => "multi_valued_preferences_tag_position_idx", :unique => true
  end
  
  def self.down
    remove_index "cluster_groups", :name => "index_cluster_groups_unique"
    ClusterGroup.delete_all
    MultiValuedPreference.preference( :homepage_clusters ).each{ |x| x.destroy }
    add_index "cluster_groups", ["owner_type", "owner_id", "name"], :name => "index_cluster_groups_on_owner_type_and_owner_id_and_name", :unique => true
    remove_index "multi_valued_preferences", :name => "multi_valued_preferences_tag_position_idx"
    remove_column "multi_valued_preferences", "tag"
    add_index "multi_valued_preferences", ["owner_type", "owner_id", "preference_id", "position", "value"], :name => "multi_valued_preferences_position_idx", :unique => true
  end
  
end