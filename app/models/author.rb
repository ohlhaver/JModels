class Author < ActiveRecord::Base
  
  has_many  :story_authors
  has_many  :stories, :through => :story_authors, :source => :story
  
  define_index do
    indexes :name, :as => :name
    set_property :delta => :delayed
  end
  
  before_save :set_delta_index_story
  after_save :set_story_delta_flag
  after_destroy :set_story_delta_flag
  
  def set_delta_index_story
    @delta_index_story = name_changed?
    return true
  end
  
  def set_story_delta_flag
    stories.find_each{ |story| story.update_attribute( :delta, true ) } if frozen? || @delta_index_story
  end
  
end
