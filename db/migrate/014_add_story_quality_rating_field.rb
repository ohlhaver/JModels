class AddStoryQualityRatingField < ActiveRecord::Migration
  
  def self.up
    add_column :stories, :quality_rating, :float
  end
  
  def self.down
    remove_column :stories, :quality_rating
  end
  
end