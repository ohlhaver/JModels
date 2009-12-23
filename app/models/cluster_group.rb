#
# Need to create cluster_group based score for each story_group created
#
class ClusterGroup < ActiveRecord::Base
  
  belongs_to :owner, :polymorphic => true
  belongs_to :perspective, :polymorphic => true
  belongs_to :category
  belongs_to :language
  
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
  
end