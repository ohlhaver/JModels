class CreateTableLanguageThresholds < ActiveRecord::Migration
  
  def self.up
    add_column :languages, :cluster_threshold, :integer, :default => 5, :null => false
    Language.find(:first, :conditions => { :code => 'de' } ).update_attributes( :cluster_threshold => 4 )
  end
  
  def self.down
    remove_column :languages, :cluster_threshold
  end
end