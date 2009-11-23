class RestructureForBg < ActiveRecord::Migration
  
  def self.up
    drop_table :keyword_subscriptions
    drop_table :keywords
    remove_column :story_metrics, :keyword_exists
  end
  
  def self.down
    raise 'Cannot Rollback'
  end
  
end