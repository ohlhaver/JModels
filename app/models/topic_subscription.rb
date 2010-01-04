class TopicSubscription < ActiveRecord::Base
  
  attr_accessor :stories_to_serialize
  
  serialize_with_options do
    dasherize false
    except :owner_id, :owner_type, :search_any, :search_all, :search_except, :search_exact_phrase, :region_id, :source_id, :author_id, :time_span, :sort_criteria, 
      :category_id, :blog, :video, :opinion, :subscription_type, :story_search_hash
    map_include :stories => :stories_serialize
  end
  
  belongs_to :owner, :polymorphic => true
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [ :owner_type, :owner_id ]
  validate :validates_presence_of_search_keywords
  
  belongs_to :author
  belongs_to :category
  belongs_to :source
  belongs_to :region
  
  before_save :populate_story_search_hash
  
  serialize :story_search_hash
  
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
  
  protected
  
  def populate_story_search_hash
    if( story_search_hash.blank? || search_all_changed? || search_any_changed? || search_exact_phrase_changed? ||
      search_except_changed? )
      self.story_search_hash = StorySearch.new( owner, :advance, attributes.symbolize_keys ).to_hash
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