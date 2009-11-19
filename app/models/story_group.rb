class StoryGroup < ActiveRecord::Base
  
  serialize :top_keywords
  
  has_many :memberships, :class_name => 'StoryGroupMembership', :foreign_key => 'group_id', :dependent => :delete_all
  
  has_many :stories, :through => :memberships, :source => :story
  
  has_many :top_stories, :class_name => 'Story', :through => :memberships, :source => :story, :limit => 3, :order => 'blub_score DESC, story_group_memberships.created_at DESC'
  
  has_one :top_story, :class_name => 'Story', :through => :memberships, :source => :story, :order => 'blub_score DESC, story_group_memberships.created_at DESC'
  
  named_scope :by_session, lambda { |session|
    { :conditions => { :bj_session_id => session.id } }
  }
  
  named_scope :current_session, :conditions => { :bj_session_id => BjSession.last(BjSession::Jobs::GroupGeneration).id }
  
end