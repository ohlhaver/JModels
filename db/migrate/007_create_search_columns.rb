class CreateSearchColumns < ActiveRecord::Migration
  def self.up
    add_column :authors, :delta, :boolean, :default => true, :null => false
    add_column :sources, :default_rating, :float
    add_column :authors, :default_rating, :float
    
    #
    # Story Metric Information
    # Story belongs to which group and which cluster, is it a duplicate story etc.
    #
    create_table :story_metrics do |t|
      t.integer :story_id
      t.integer :group_id
      t.integer :cluster_id
      t.integer :master_id       # in case of duplicate
    end
    add_index :story_metrics, [ :story_id, :group_id ], :name => 'story_metrics_story_group_idx'
    add_index :story_metrics, [ :story_id, :cluster_id ], :name => 'story_metrics_story_cluster_idx'
    add_index :story_metrics, [ :master_id, :story_id ]
  end
  
  def self.down
    remove_column :authors, :delta
    remove_column :sources, :default_rating
    remove_column :authors, :default_rating
    drop_table :story_metrics
  end
end