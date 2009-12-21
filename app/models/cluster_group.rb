#
# Need to create cluster_group based score for each story_group created
#
class ClusterGroup < ActiveRecord::Base
  
  belongs_to :owner
  validates_uniqueness_of :name, :scope => [ :owner_type, :owner_id ]
  
  named_scope :public, lambda{ { :conditions => { :public => true } } }
  named_scope :owner, lambda{ |owner| { :conditions => { :owner_id => owner.id, :owner_type => owner.class.name } } }
  
end