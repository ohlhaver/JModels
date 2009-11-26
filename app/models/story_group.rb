class StoryGroup < ActiveRecord::Base
  
  serialize :top_keywords
  
  has_many :memberships, :class_name => 'StoryGroupMembership', :foreign_key => 'group_id', :dependent => :delete_all
  
  has_many :stories, :through => :memberships, :source => :story, :order => 'blub_score DESC, story_group_memberships.created_at DESC' do
    
    def find_non_duplicates(*args)
      with_scope( :find => { :conditions => 'story_group_memberships.master_id IS NULL' } ) do
        find(*args)
      end
    end
    
    def find_duplicates(*args)
      with_scope( :find => { :conditions => 'story_group_memberships.master_id IS NOT NULL' } ) do
        find(*args)
      end
    end
    
  end
  
  has_many :top_stories, :class_name => 'Story', 
    :through => :memberships, :source => :story, :limit => 3, :order => 'blub_score DESC, story_group_memberships.created_at DESC',
    :conditions => 'story_group_memberships.master_id IS NULL'
  
  has_one :top_story, :class_name => 'Story', 
    :through => :memberships, :source => :story, :order => 'blub_score DESC, story_group_memberships.created_at DESC',
    :conditions => 'story_group_memberships.master_id IS NULL'
  
  named_scope :by_session, lambda { |session|
    { :conditions => { :bj_session_id => session.id } }
  }
  
  named_scope :current_session, lambda{ { :conditions => { :bj_session_id => BjSession.current(BjSession::Jobs::GroupGeneration).try(:id) }, :order => 'broadness_score DESC' } }
  
end