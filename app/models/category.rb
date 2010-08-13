class Category < ActiveRecord::Base
  
  unless defined?( Default )
    Default = [ "POL", "BUS", "SPO", "TEC", "SCI", "CUL", "MIX", "OPI" ]
    Top = [ "POL", "BUS", "CUL", "SCI", "TEC", "OPI", "MIX", "SPO" ]
    Map = { :top_stories_cluster_group => :Top, :default => :Default }
    Weights = { "MIX" => { 'de' => 0.5 } , "SPO" => 0.333 }
  end
  
  serialize_with_options( :short ) do
    dasherize false
    only :id, :code
  end
  
  named_scope :code, lambda{ |code| { :conditions => { :code => code } } }
  
  validates_presence_of   :id, :name, :code
  validates_uniqueness_of :code
  
  def self.for_select( reload = false )
    @@categories_for_select = nil if reload
    @@categories_for_select ||= Category.all( :select => 'id, name' ).collect{ |x| [ x.name, x.id ] }
  end
  
  def self.hash_map( filter = :default, options = {} )
    options.reverse_merge!( :keys => :symbol, :values => :id ) 
    hash = Hash.new
    constant_name = Category::Map[ filter.try( :to_sym ) ]
    return hash  unless constant_name
    Category.find( :all, :conditions => { :code => self.const_get( constant_name ) } ).each do | category |
     key = ( options[:keys] == :symbol ? category.code.downcase.sym : category.code )
     hash[ key ] = ( options[:values] == :record ) ? category : category.send( values )
    end
    return hash
  end
  
  def self.collection( filter = :default )
    map = hash_map( filter, :keys => :string, :values => :record )
    return [] if map.blank?
    constant_name = Category::Map[ filter.try( :to_sym ) ]
    self.const_get( constant_name ).collect{ |code| map[ code ] }.select{ |category| !category.nil? }
  end
  
  def self.top_category_id( category_ids )
    return nil if category_ids.blank?
    groups = category_ids.group_by{ |x| x }
    groups.each_pair{ |k,v| groups[k] = v.size }
    unique_category_ids = groups.keys.sort_by{ |x| -groups[x] }
    candidate_category_ids = main_category_ids( unique_category_ids )
    return nil if candidate_category_ids.empty?
    top_count = groups[ candidate_category_ids.first ]
    top_category_ids = candidate_category_ids.select{ |x| groups[x] == top_count }
    return prefered_category_id( top_category_ids )
  end
  
  def self.main_category_ids( category_ids )
    hash_map = find(:all, :conditions => { :id => category_ids }).inject({}){ |s,x| s[x.id] = x; s }
    category_ids.select{ |cid| Category::Default.include?( hash_map[cid.to_i].try(:code) ) }
  end
  
  def self.prefered_category_id( category_ids )
    category_ids.sort!
    category_ids.first
  end
  
  def default?
    Default.include?( code )
  end
  
end
