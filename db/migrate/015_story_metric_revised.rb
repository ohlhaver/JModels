class StoryMetricRevised < ActiveRecord::Migration
  
  def self.up
    StoryMetric.delete_all
    add_index :story_metrics, [:story_id], :unique => true, :name => 'story_metrics_unique_idx'
    remove_index :story_metrics, :name => 'story_metrics_story_group_idx'
    remove_index :story_metrics, :name => 'story_metrics_story_cluster_idx'
    remove_column :story_metrics, :group_id
    remove_column :story_metrics, :cluster_id
  end
  
  def self.down
    remove_index :story_metrics, :name => 'story_metrics_unique_idx'
    add_column :story_metrics, :group_id, :integer
    add_column :story_metrics, :cluster_id, :integer
    add_index :story_metrics, [ :story_id, :group_id ], :name => 'story_metrics_story_group_idx'
    add_index :story_metrics, [ :story_id, :cluster_id ], :name => 'story_metrics_story_cluster_idx'
  end
  
end