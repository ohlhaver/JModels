class Author < ActiveRecord::Base
  
  serialize_with_options do
    dasherize false
    except :default_rating, :default_preference, :delta, :block
  end
  
  serialize_with_options( :short ) do
    dasherize false
    only :id, :name
  end
  
  attr_accessor :skip_uniqueness_validation
  attr_accessor :skip_delta_callbacks
  
  has_one   :priority_author, :dependent => :delete
  has_many  :story_authors, :dependent => :delete_all
  has_many  :stories, :through => :story_authors, :source => :story
  has_many  :aliases, :class_name => 'AuthorAlias', :dependent => :delete_all
  has_many  :author_subscriptions, :dependent => :delete_all
  
  validates_presence_of :name
  
  validates_uniqueness_of                     :name, :if => Proc.new{ |r| !r.skip_uniqueness_validation }
  validate_on_create :uniqueness_of_name_in_aliases, :if => Proc.new{ |r| !r.skip_uniqueness_validation }
  
  named_scope :with_subscription_count, lambda{ 
    { 
      :select => 'authors.*, COUNT(*) AS subscription_count',
      :joins => "INNER JOIN author_subscriptions ON ( author_subscriptions.author_id = authors.id AND author_subscriptions.subscribed = #{connection.quoted_true})",
      :group => 'authors.id',
      :conditions => { :is_agency => false }
    }
  }
  
  named_scope :top, lambda{
    {
      :select => 'authors.*, ta.subscription_count', 
      :joins => "INNER JOIN bg_top_authors AS ta ON ( ta.author_id = authors.id AND ta.active = #{connection.quoted_true})",
      :conditions => 'ta.subscription_count > 0', 
      :order => 'ta.subscription_count DESC'
    }
  }
  
  define_index do
    indexes :name, :as => :name, :sortable => true
    indexes aliases(:name), :as => :aliases
    has :is_agency
    has :is_opinion
    has :block
    has :id, :as => :author_id
    set_property :delta => :delayed
  end
  
  # To overcome thinking sphinx bug where deleted item is not flagged from author_core index
  unless respond_to?( :destroy_with_ts_bugfix )
    def destroy_with_ts_bugfix
      update_attribute( :delta, true )
      destroy_without_ts_bugfix
    end
    alias_method_chain :destroy, :ts_bugfix
  end
  
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
        a_n = a_n.chars[0, 100] # author names are truncated at 100 chars
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
  
  def self.map( story_ids )
    find( 
      :all, :select => 'authors.*, story_authors.story_id AS story_id', 
      :joins => 'INNER JOIN story_authors ON ( story_authors.author_id = authors.id )', 
      :conditions => { :story_authors => { :story_id => story_ids }, :authors => { :block => false } } 
    ).group_by{ |a| a.send( :read_attribute, :story_id ).to_i }
  end
  
  # Please use this operation to block an Author
  def block!
    StoryAuthor.update_all( 'block = 1', { :author_id => self.id } )
    AuthorSubscription.update_all( 'block = 1', { :author_id => self.id } )
    self.update_attributes( :delta => true, :block => true )
    stories.find_each(:select => 'id, delta'){ |story| story.update_attribute( :delta, true ) }
  end
  
  # Please use this operation to unblock an Author
  def unblock!
    StoryAuthor.update_all( 'block = 0', { :author_id => self.id } )
    AuthorSubscription.update_all( 'block = 0', { :author_id => self.id } )
    self.update_attributes( :delta => true, :block => false )
    stories.find_each(:select => 'id, delta'){ |story| story.update_attribute( :delta, true ) }
  end
  
  #
  # Merges a set of authors to the author that invokes the merge_author message.
  # AuthorAliases are moved to the new author. Author stories are migrated
  #
  def merge_authors( authors )
    Array(authors).each{ |author| merge_author(author) }
  end
  
  def subscription_count
    write_attribute( :subscription_count, self.class.subscription_count( self.id ) )  unless has_attribute?( :subscription_count )
    Integer( read_attribute( :subscription_count ) )
  end
  
  def top_author?
    subscription_count > 2
  end
  
  def self.subscription_count( author_id )
    self.connection.select_value( "SELECT subscription_count FROM bg_top_authors WHERE author_id = #{author_id}" ) || "0"
  end
  
  def self.import_old_author( author_attrs = {} )
    subscribers = author_attrs.delete( "subscribers" )
    author_name = author_attrs.delete( "name" )
    authors = create_or_find( author_name )
    authors.each{ |a| a.update_attributes( author_attrs ) }
    users = User.find( :all, :conditions => { :login => subscribers } )
    users.each do |user|
      power_plan = true
      unless user.power_plan?
        power_plan = false
        user.account_status_points.create( :plan_id => 1, 
          :billing_record_id => 0, 
          :starts_at => Time.now.utc - 10, 
          :ends_at => Time.now.utc + 30.days 
        )
        user.instance_variable_set('@plan_id', 1)
      end
      authors.each do |author|
        user.author_subscriptions.create( :author_id => author.id, :subscribed => true )
      end
      unless power_plan
        user.account_status_points.delete_all
      end
    end
    return authors
  end
  
  def self.import_old_data( xml )
    authors = Hash.from_xml( xml )["authors"] rescue []
    count = 0
    authors.each do |author_attrs|
      begin
        count += import_old_author( author_attrs ).size
      rescue StandardError
      end
    end
    return count
  end
  
  protected
  
  def merge_author( author )
    return unless author.is_a?( Author )
    #StoryAuthor.transaction do
      author.stories.find_each{ |story| story.update_attribute( :delta, true ) }
      #Story.update_all( "delta = #{Story.connection.quoted_true}", 
      #  [ 'id IN ( SELECT story_id FROM story_authors WHERE author_id = :author_id )', { :author_id => author.id } ] )
      # Merge all Author Subscriptions
      AuthorSubscription.update_all( "author_id = '#{self.id}', block = '#{self.block? ? 1 : 0}'", { :author_id => author.id } )
      # Merge all the Stories
      StoryAuthor.update_all( "author_id = '#{self.id}', block = '#{self.block? ? 1 : 0}'", { :author_id => author.id } )
      # Merge all the Author Aliases
      AuthorAlias.update_all( "author_id = '#{self.id}'", { :author_id => author.id } )
      author.skip_delta_callbacks = true
      author.destroy
      self.update_attribute( :delta, true )
      self.stories.find_each( :conditions => { :delta => true } ){  |story| story.update_attribute( :delta, true ) }
    #end
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
    @delta_index_story = name_changed? && !block?
    return true
  end
  
  def set_story_delta_flag
    return unless frozen? || @delta_index_story
    Story.transaction do
      self.stories.find_each{ |story| story.update_attribute( :delta, true ) }
    end
  end
  
end
