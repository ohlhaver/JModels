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
  
  def self.create_or_find(author_names)
    authors = []
    author_names.each do |a_n|
      a_n = a_n[0, 100] # author names are truncated at 100 chars
      a = self.find( a_n )
      a_n = a_n.chars.upcase.to_s
      a ||= self.find_or_initialize_by_name( a_n )
      if a.new_record?
        a.is_agency = false
        a = a.save ? a : nil
      end
      authors.push( a ) if a
    end
    return authors
  end
  
  protected
  
  def set_delta_index_story
    @delta_index_story = name_changed?
    return true
  end
  
  def set_story_delta_flag
    stories.find_each{ |story| story.update_attribute( :delta, true ) } if frozen? || @delta_index_story
  end
  
end
