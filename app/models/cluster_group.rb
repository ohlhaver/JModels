#
# Need to create cluster_group based score for each story_group created
#
class ClusterGroup < ActiveRecord::Base
  
  belongs_to :owner, :polymorphic => true
  belongs_to :perspective, :polymorphic => true
  belongs_to :category
  belongs_to :language
  
  has_many :memberships, :class_name => 'ClusterGroupMembership'
  has_many :story_groups, :through => :memberships, :as => :story_group, :conditions => { :active => true }, :order => 'broadness_score DESC'
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [ :owner_type, :owner_id, :perspective_type, :perspective_id, :language_id ]
  
  named_scope :public, lambda{ { :conditions => { :public => true } } }
  named_scope :owner, lambda{ |owner| { :conditions => { :owner_id => owner.id, :owner_type => owner.class.name } } }
  
  named_scope :region, lambda{ |region| 
    region = region.id if region.class.name == 'Region'
    { :conditions => { :perspective_type => 'Region', :perspective_id => region } }
  }
  
  named_scope :language, lambda{ |language| 
    language = language.id if language.class.name == 'Language'
    { :conditions => { :language_id => language } }
  }
  
  named_scope :perspective, lambda{ |perspective| 
    { :conditions => { :perspective_id => perspective.id, :perspective_type => perspective.class.name } }
  }
  
  named_scope :homepage, lambda{ |*args|
    options = args.last.is_a?( Hash ) ? args.pop : {}
    owner = ( args.empty? || args.first.nil? ) ? User.find(:first, :conditions => { :login => 'jadmin' } ) : args.first
    cluster_group_ids = MultiValuedPreference.preference( :homepage_clusters ).owner( owner ).tag( options[:tag] ).collect{ |x| x.value }
    { :conditions => { :id => cluster_group_ids } }
  }
  
  def self.for_select( options = {} )
    homepage( options ).all( :select => 'id, name' ).collect{ |x| [ x.name, x.id ] }
  end
  
  def self.stories( cluster_group_ids, per_cluster_group = 2, per_cluster = 3 )
    cluster_group_ids.push( { :limit => per_cluster_group, :offset => 0 } )
    clusters = StoryGroup.active_session.by_cluster_group_ids( *cluster_group_ids ).all( 
      :include => :top_stories )
    cluster_group_ids.pop # popping out options parameter
    StoryGroup.populate_stories_to_serialize( clusters, per_cluster )
    clusters = clusters.group_by{ |x| x.send( :read_attribute, :cluster_group_id ) }
    cluster_groups = cluster_group_ids.collect{ |id| { :id => id.to_i , :clusters => clusters[ id ] } }
    cluster_groups.delete_if{ |x| x[:clusters].blank? }
  end
end