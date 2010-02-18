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
    position = 0
    position_statement = cluster_group_ids.inject([]){ |s,i| position += 1;s.push( "WHEN #{i} THEN #{position}");  }
    position_statement = "CASE (id) #{position_statement.join(' ')} END AS position"
    { :select => "*, #{position_statement}", :conditions => { :id => cluster_group_ids } }
  }
  
  def self.for_select( options = {} )
    homepage( options ).all( :select => 'id, name' ).collect{ |x| [ x.name, x.id ] }
  end
  
  # Top Clusters are Removed From Other Cluster Groups
  # Opinions are Top Authors so they must be removed but order must be maintained
  def self.stories( user, cluster_group_ids, per_cluster_group = 2, per_cluster = 3, top_clusters = [] )
    clusters = []
    cluster_names = {}
    opinions = nil
    opinions_stories = []
    unless cluster_group_ids.blank?
      cluster_names = ClusterGroup.find(:all, :select => 'id, name', :conditions => { :id => cluster_group_ids } ).inject({}){ |s,r| s.merge!( r.id => r.name ); s }
      args = cluster_group_ids.dup
      opinions = self.get_opinions!( args )
      args.push( { :limit => per_cluster_group, :exclude_cluster_ids => top_clusters.collect(&:id), :user => user } )
      clusters = StoryGroup.active_session.by_cluster_group_ids( *args ).all
    end
    top_clusters.inject( clusters ){ |ac,tc| ac.push( tc ) }
    StoryGroup.populate_stories_to_serialize( user, clusters, per_cluster )
    clusters = clusters.group_by{ |x| top_clusters.include?( x ) ? 'top' : x.send( :read_attribute, :cluster_group_id ) }
    opinions_stories = yield( opinions ) if block_given? && opinions
    cluster_groups = cluster_group_ids.collect{ |id|
      id = id.to_i 
      if opinions && opinions.id == id
        { :id => id, :name => cluster_names[ id ], :stories => opinions_stories }
      else
        { :id => id, :name => cluster_names[ id ], :clusters => clusters[ id.to_s ] } 
      end
    }
    cluster_groups.insert( 0, { :id => 'top', :name => 'Top Stories', :clusters => clusters[ 'top' ] } )
    cluster_groups.delete_if{ |x| x[ :clusters ].blank? && x[ :stories ].blank? }
  end
  
  def opinions?
    category_id = Preference.select_value_by_name_and_code( :category_id, :opi ).try( :[], :id )
    self.category_id == category_id
  end
  
  protected
  
  def self.get_opinions!( cluster_group_ids )
    category_id = Preference.select_value_by_name_and_code( :category_id, :opi ).try( :[], :id )
    opinion = ClusterGroup.find( :first, :conditions => { :id => cluster_group_ids, :category_id => category_id } )
    cluster_group_ids.delete_if{ |x| x.to_s == opinion.id.to_s } if opinion
    return opinion
  end
  
end