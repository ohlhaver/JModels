class Author < ActiveRecord::Base
  
  attr_accessor :skip_uniqueness_validation
  
  has_many  :story_authors
  has_many  :stories, :through => :story_authors, :source => :story
  has_many  :aliases, :class_name => 'AuthorAlias'
  
  after_create :create_default_author_alias
  
  validates_presence_of :name
  
  validates_uniqueness_of :name, :if => Proc.new{|r| !r.skip_uniqueness_validation }
  validate_on_create :uniqueness_of_name_in_aliases, :if => Proc.new{ |r| !r.skip_uniqueness_validation }
  
  define_index do
    indexes :name, :as => :name, :sortable => true
    indexes aliases(:name), :as => :aliases
    has :is_agency
    has :id, :as => :author_id
    set_property :delta => :delayed
  end
  
  before_save :set_delta_index_story
  after_save :set_story_delta_flag
  after_destroy :set_story_delta_flag
  
  def self.create_or_find( author_names )
    authors = []
    author_names.each do |name|
      a_ns = Array( JCore::Clean.author( name ) )
      a_ns.each do |a_n|
        a_n = a_n[0, 100] # author names are truncated at 100 chars
        a_n = a_n.chars.upcase.to_s
        a ||= self.find_or_initialize_by_name( a_n )
        if a.new_record?
          a.is_agency =  JCore::Clean.agency?( a_n )
          a = ( a.save && !a.frozen? ) ? a : self.find_or_initialize_by_name( a_n )
        end
        authors.push( a ) unless a.new_record?
      end
    end
    authors.uniq!
    return authors
  end
  
  # First look at the AuthorAlias Table
  # Then look at Authors Table
  # If not found Initialize the new object
  def self.find_or_initialize_by_name( name )
    author_alias = AuthorAlias.find( :first, :conditions => { :name => name } )
    author = ( author_alias.try( :author ) || find( :first, :conditions => { :name => name } ) || new( :name => name, :skip_uniqueness_validation => true ) )
  end
  
  protected
  
  def create_default_author_alias
    success = AuthorAlias.create!( :name => self.name, :author_id => self.id, :skip_uniqueness_validation => true ) rescue false
    self.destroy unless success
  end
  
  def uniqueness_of_name_in_aliases
    #author_alias_author_id = AuthorAlias.find(:first, :conditions => { :name => name.chars.upcase.to_s }, :select => 'author_id' ).try( :author_id )
    #errors.add( :name, :taken ) if author_alias_author_id && self.id != author_alias_author_id
    errors.add( :name, :taken ) if AuthorAlias.exists?( { :name => name.chars.upcase.to_s } )
  end
  
  
  def set_delta_index_story
    @delta_index_story = name_changed?
    return true
  end
  
  def set_story_delta_flag
    stories.find_each{ |story| story.update_attribute( :delta, true ) } if frozen? || @delta_index_story
  end
  
end
