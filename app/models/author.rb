class Author < ActiveRecord::Base
  
  attr_accessor :skip_uniqueness_validation
  attr_accessor :skip_delta_callbacks
  
  has_many  :story_authors
  has_many  :stories, :through => :story_authors, :source => :story
  has_many  :aliases, :class_name => 'AuthorAlias'
  
  validates_presence_of :name
  
  validates_uniqueness_of                     :name, :if => Proc.new{|r| !r.skip_uniqueness_validation }
  validate_on_create :uniqueness_of_name_in_aliases, :if => Proc.new{ |r| !r.skip_uniqueness_validation }
  
  define_index do
    indexes :name, :as => :name, :sortable => true
    indexes aliases(:name), :as => :aliases
    has :is_agency
    has :id, :as => :author_id
    set_property :delta => :delayed
  end
  
  # To overcome thinking sphinx bug where deleted item is not flagged from author_core index
  def destroy_with_ts_bugfix
    update_attribute( :delta, true )
    destroy_without_ts_bugfix
  end
  
  alias_method_chain :destroy, :ts_bugfix
  
  after_create  :create_default_author_alias
  before_save   :set_delta_index_story, :if => Proc.new{ |r| !r.skip_delta_callbacks }
  after_save    :set_story_delta_flag,  :if => Proc.new{ |r| !r.skip_delta_callbacks }
  after_destroy :set_story_delta_flag,  :if => Proc.new{ |r| !r.skip_delta_callbacks }
  
  #
  # Methods check whether the author name exists in our database. It also refers AuthorAlias table
  # If it exists then it returns the author object otherwise initialize a new author object 
  # with the author_name. By default skip_uniqueness_validation is turn true because we initialized
  # the object only after finding through our database for existing author
  #
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
  
  #
  # First look at the AuthorAlias Table
  # Then look at Authors Table
  # If not found Initialize the new object with skip_uniqueness_validation true
  #
  def self.find_or_initialize_by_name( name )
    author_alias = AuthorAlias.find( :first, :conditions => { :name => name } )
    author = ( author_alias.try( :author ) || find( :first, :conditions => { :name => name } ) || new( :name => name, :skip_uniqueness_validation => true ) )
  end
  
  #
  # Merges a set of authors to the author that invokes the merge_author message.
  # AuthorAliases are moved to the new author. Author stories are migrated
  #
  def merge_authors( authors )
    Array(authors).each{ |author| merge_author(author) }
  end
  
  protected
  
  def merge_author( author )
    return unless author.is_a?( Author )
    StoryAuthor.transaction do
      Story.update_all( "delta = #{Story.connection.quoted_true}", 
        [ 'id IN ( SELECT story_id FROM story_authors WHERE author_id = :author_id )', { :author_id => author.id } ] )
      StoryAuthor.update_all( "author_id = '#{self.id}'", { :author_id => author.id } )
      AuthorAlias.update_all( "author_id = '#{self.id}'", { :author_id => author.id } )
      author.skip_delta_callbacks = true
      author.destroy
      self.update_attribute( :delta, true )
      self.stories.find_each( :conditions => { :delta => true } ){  |story| story.update_attribute( :delta, true ) }
    end
  end
  
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
    return unless frozen? || @delta_index_story
    Story.transaction do
      self.stories.find_each{ |story| story.update_attribute( :delta, true ) }
    end
  end
  
end
