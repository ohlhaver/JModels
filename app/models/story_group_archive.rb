class StoryGroupArchive < ActiveRecord::Base
  
  set_primary_key :group_id
  
  attr_accessor :stories_to_serialize
  
  attr_accessor :authors_pool # global pool of authors, #used in case of serialization
  attr_accessor :sources_pool # gloable pool of sources, #used in case of serialization
  attr_accessor :image_path_cache
  attr_accessor :url
  
  serialize_with_options do
    dasherize false
    except :bj_session_id, :created_at, :thumbnail_story_id, :thumbnail_exists, :top_keywords, :cluster_group_id, :group_id
    map_include :top_keywords => :top_keywords_serialize, :stories => :stories_serialize, :image => :image_serialize, :url => :url_serialize
    map :id => :group_id
  end
  
  serialize :top_keywords
  
  has_many :memberships, :class_name => 'StoryGroupMembershipArchive', :foreign_key => 'group_id'
  
  has_many :unique_memberships, :class_name => 'StoryGroupMembershipArchive', :foreign_key => 'group_id', :conditions => 'story_group_membership_archives.master_id IS NULL',
    :order => 'story_group_membership_archives.blub_score DESC'
  
  has_many :top_stories, :class_name => 'Story', :through => :unique_memberships, :source => :story, :order => 'story_group_membership_archives.blub_score DESC'
  
  has_many :stories, :through => :memberships, :source => :story, :order => 'story_group_membership_archives.blub_score DESC'
  
  protected
  
  def url_serialize( options = {} )
    url.to_xml( :root => options[:root], :builder => options[:builder], :skip_instruct => true )
  end
  
  def top_keywords_serialize( options = {} )
    top_keywords.to_xml( options.merge( :children => 'keyword' ) )
  end
  
  def top_stories_serialize( options = {} )
    ( top_stories[0...3] ).to_xml( :set => :short, :root => options[:root], :builder => options[:builder], :skip_instruct=>true, :children => 'story' )
  end
  
  def stories_serialize( options = {} )
    self.stories_to_serialize ||= top_stories[0...3]
    unless stories_to_serialize.blank?
      self.authors_pool ||= Author.map( stories_to_serialize.collect(&:id) )
      self.sources_pool ||= Source.find(:all, :conditions => { :id => stories_to_serialize.collect( &:source_id ).uniq } ).inject({}){ |map, source| map[ source.id ] = source; map }
      stories_to_serialize.each{ |story| story.authors_to_serialize = self.authors_pool[ story.id ] || []; story.source_to_serialize = self.sources_pool[ story.source_id ] }
    end
    stories_to_serialize.to_xml( :root => options[:root], :builder => options[:builder], :skip_instruct=>true )
  end
  
  def image_serialize( options = {} )
    ( image_path_cache ? "http://cdn.jurnalo.com#{image_path_cache}" : nil ).to_xml( :root => options[:root], :builder => options[:builder], :skip_instruct => true )
  end
  
end