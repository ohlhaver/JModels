class StoryGroupArchive < ActiveRecord::Base
  
  set_primary_key :group_id
  
  attr_accessor :stories_to_serialize
  attr_accessor :authors_pool # global pool of authors, #used in case of serialization
  
  serialize_with_options :custom do
    dasherize false
    except :bj_session_id, :created_at, :thumbnail_story_id, :thumbnail_exists, :top_keywords
    map_include :top_keywords => :top_keywords_serialize, :stories => :stories_serialize
  end
  
  serialize_with_options do
    dasherize false
    except :bj_session_id, :created_at, :thumbnail_story_id, :thumbnail_exists, :top_keywords
    map_include :top_stories => :top_stories_serialize, :top_keywords => :top_keywords_serialize
  end
  
  serialize :top_keywords
  
  has_many :memberships, :class_name => 'StoryGroupMembershipArchive', :foreign_key => 'group_id'
  
  has_many :unique_memberships, :class_name => 'StoryGroupMembershipArchive', :foreign_key => 'group_id', :conditions => 'story_group_membership_archives.master_id IS NULL',
    :order => 'story_group_membership_archives.blub_score DESC'
  
  has_many :top_stories, :class_name => 'Story', :through => :unique_memberships, :source => :story, :order => 'story_group_membership_archives.blub_score DESC'
  
  protected
  
  def top_keywords_serialize( options = {} )
    top_keywords.to_xml( options.merge( :children => 'keyword' ) )
  end
  
  def top_stories_serialize( options = {} )
    ( top_stories[0...3] ).to_xml( :set => :short, :root => options[:root], :builder => options[:builder], :skip_instruct=>true, :children => 'story' )
  end
  
  def stories_serialize( options = {} )
    stories_to_serialize ||= top_stories[0...3]
    unless stories_to_serialize.blank?
      self.authors_pool ||= Author.find(:all, :select => 'authors.*, story_authors.story_id AS story_id', :joins => 'INNER JOIN story_authors ON ( story_authors.author_id = authors.id )', 
        :conditions => { :story_authors => { :story_id => stories_to_serialize.collect(&:id) } } ).group_by{ |a| a.send( :read_attribute, :story_id ).to_i }
      stories_to_serialize.each{ |story| story.authors_to_serialize = self.authors_pool[ story.id ] || [] }
    end
    stories_to_serialize.to_xml( :root => options[:root], :builder => options[:builder], :skip_instruct=>true )
  end
  
end