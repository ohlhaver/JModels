#
# StoryGroup is equivalent to Cluster
#
class StoryGroup < ActiveRecord::Base
  
  attr_accessor :stories_to_serialize
  attr_accessor :authors_pool # global pool of authors, #used in case of serialization
  
  serialize_with_options do
    dasherize false
    except :bj_session_id, :created_at, :thumbnail_story_id, :thumbnail_exists, :top_keywords, :cluster_group_id
    map_include :top_keywords => :top_keywords_serialize, :stories => :stories_serialize
  end
  
  # serialize_with_options do
  #   dasherize false
  #   except :bj_session_id, :created_at, :thumbnail_story_id, :thumbnail_exists, :top_keywords
  #   map_include :top_stories => :top_stories_serialize, :top_keywords => :top_keywords_serialize
  # end
  
  serialize :top_keywords
  
  belongs_to :language
  
  has_many :memberships, :class_name => 'StoryGroupMembership', :foreign_key => 'group_id', :dependent => :delete_all
  
  has_many :top_memberships, :class_name => 'StoryGroupMembership', :foreign_key => 'group_id', :conditions => 'story_group_memberships.master_id IS NULL',
    :order => 'story_group_memberships.rank ASC'
  
  has_many :top_stories, :class_name => 'Story', :through => :top_memberships, :source => :story,  :order => 'story_group_memberships.rank ASC'
  
  has_many :stories, :through => :memberships, :source => :story, :order => 'rank ASC' do
    
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
  
  named_scope :by_session, lambda { |session|
    { :conditions => { :bj_session_id => session.id } }
  }
  
  named_scope :current_session, lambda{ { :conditions => { :bj_session_id => BjSession.current(BjSession::Jobs::GroupGeneration).try(:id) }, :order => 'broadness_score DESC' } }
  
  named_scope :active_session, lambda{ { :conditions => { :bj_session_id => BjSession.current(BjSession::Jobs::GroupGeneration).try(:id) } } }
  
  named_scope :by_cluster_group_ids, lambda{ |*args|
    options = args.last.is_a?( Hash ) ? args.pop : {}
    options.reverse_merge!( :limit => 3, :offset => 0 )
    rank_start = options[:offset].to_i
    rank_end = rank_start + options[:limit].to_i
    { 
      :select => %Q( story_groups.*, cgm.broadness_score AS broadness_score, cgm.cluster_group_id ),
      :joins => %Q( INNER JOIN cluster_group_memberships AS cgm ON ( cgm.story_group_id = story_groups.id AND cgm.active = #{connection.quoted_true} AND 
        rank > #{connection.quote( rank_start )} AND rank <= #{connection.quote( rank_end ) } AND cgm.cluster_group_id IN (#{ args.join(',') }) ) ),
      :order => 'cgm.rank ASC'
    }
  }
  
  #
  # This function calculates the cluster groups dynamically
  # Should be called by Background Process
  #
  def self.find_each_for_cluster_group( cluster_group, &block)
     source_ids = cluster_group.perspective.source_ids
     StoryGroup.find_each( {
        :select => 'story_groups.*, COUNT( DISTINCT source_id ) + ( COUNT( * ) / 100 ) AS broadness_score',
        :joins => 'LEFT OUTER JOIN story_group_memberships AS sgm ON ( sgm.group_id = story_groups.id)',
        :conditions  => { :sgm => { :source_id => source_ids }, 
          :category_id => cluster_group.category_id, 
          :language_id => cluster_group.language_id 
        },
        :group => 'story_groups.id'
      }, &block )
  end
  
  def self.populate_stories_to_serialize( clusters, per_cluster = 3 )
    story_ids = clusters.inject([]) do | acc, cluster| 
      cluster.stories_to_serialize = cluster.top_stories[ 0...per_cluster ]
      acc.push( cluster.stories_to_serialize(&:id) )
    end
    story_ids.flatten!
    authors_pool = Author.find(:all, :select => 'authors.*, story_authors.story_id AS story_id', 
      :joins => 'INNER JOIN story_authors ON ( story_authors.author_id = authors.id )', 
      :conditions => { :story_authors => { :story_id => story_ids } } 
    ).group_by{ |a| a.send( :read_attribute, :story_id ).to_i }
    clusters.each{ |cluster| cluster.authors_pool = authors_pool }
  end
  
  protected
  
  def stories_serialize( options = {} )
    stories_to_serialize ||= top_stories[0...3]
    unless stories_to_serialize.blank?
      self.authors_pool ||= Author.find(:all, :select => 'authors.*, story_authors.story_id AS story_id', :joins => 'INNER JOIN story_authors ON ( story_authors.author_id = authors.id )', 
        :conditions => { :story_authors => { :story_id => stories_to_serialize.collect(&:id) } } ).group_by{ |a| a.send( :read_attribute, :story_id ).to_i }
      stories_to_serialize.each{ |story| story.authors_to_serialize = self.authors_pool[ story.id ] || [] }
    end
    stories_to_serialize.to_xml( :root => options[:root], :builder => options[:builder], :skip_instruct=>true )
  end
  
  def top_keywords_serialize( options = {} )
    top_keywords.to_xml( options.merge( :children => 'keyword' ) )
  end
  
  def top_stories_serialize( options = {} )
    ( top_stories[0...3] ).to_xml( :set => :short, :root => options[:root], :builder => options[:builder], :skip_instruct=>true, :children => 'story' )
  end
  
end