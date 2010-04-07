class TopicSubscription < ActiveRecord::Base
  
  attr_accessor :stories_to_serialize
  
  serialize_with_options do
    dasherize false
    except :owner_id, :owner_type, :story_search_hash
    map_include :stories => :stories_serialize, :author => :author_serialize, :source => :source_serialize
    map :advanced => :advance?
  end
  
  belongs_to :owner, :polymorphic => true
  
  acts_as_list :scope => :owner
  
  #redefining scope condition # bugfix for the acts_as_list plugin
  def scope_condition
    self.class.send( :sanitize_sql_hash_for_conditions, { :owner_type => owner_type, :owner_id => owner_id } )
  end
  
  before_validation :populate_default_name
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [ :owner_type, :owner_id ]
  validate :validates_presence_of_search_keywords
  
  activate_user_account_restrictions :user => :owner, :association => :topic_subscriptions
  
  belongs_to :author
  belongs_to :category
  belongs_to :source
  belongs_to :region
  
  before_save :populate_story_search_hash
  
  serialize :story_search_hash
  
  named_scope :home_group, lambda{ { :conditions => { :home_group => true } } }
  named_scope :email_alert, lambda{ { :conditions => { :email_alert => true } } }
  
  def stories( params = {} )
    attributes_hash = HashWithIndifferentAccess.new( attributes ) 
    StorySearch.from_hash( owner, attributes_hash.merge!( params ), story_search_hash ){ |s| s.populate_options }.results
  end
  
  def filters
    f = Array.new
    f <<  { :name => 'Region', :value => region.name } if region
    f <<  { :name => 'Author', :value => author.name } if author
    f <<  { :name => 'Source', :value => source.name } if source
    f <<  { :name => 'Category', :value => category.name } if category
    return f
  end
  
  def advance?
    ( !search_all.blank? || !search_exact_phrase.blank? || !search_except.blank? || sort_criteria || time_span || 
      category_id || region_id || author_id || source_id || blog || video || opinion || subscription_type )
  end
  
  protected
  
  def author_serialize( options = {} )
    self.author.to_xml( :set => :short , :root => options[:root], :builder => options[:builder], :skip_instruct=>true )
  end
  
  def source_serialize( options = {} )
    self.source.to_xml( :set => :short, :root => options[:root], :builder => options[:builder], :skip_instruct => true )
  end
  
  def populate_default_name
    self.name = self.search_any if self.name.blank?
    return true
  end
  
  def populate_story_search_hash
    if( story_search_hash.blank? || search_all_changed? || search_any_changed? || search_exact_phrase_changed? ||
      search_except_changed? )
      self.story_search_hash = StorySearch.new( owner, :advance, attributes.symbolize_keys ).to_hash.delete_if{ |k,v| k == :options }
    end
  end
  
  def validates_presence_of_search_keywords
    if search_all.blank? && search_any.blank? && search_exact_phrase.blank?
      errors.add( :search_keywords, :required )
    end
  end
  
  def stories_serialize( options = {} )
    stories_to_serialize.to_xml( options )
  end
  
end