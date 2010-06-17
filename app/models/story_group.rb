#
# StoryGroup is equivalent to Cluster
#
class StoryGroup < ActiveRecord::Base
  
  attr_accessor :stories_to_serialize
  attr_accessor :authors_pool # global pool of authors, #used in case of serialization
  attr_accessor :sources_pool # global pool of sources, #used in case of serialization
  attr_accessor :image_path_cache
  attr_accessor :url
  
  serialize_with_options do
    dasherize false
    except :bj_session_id, :created_at, :thumbnail_story_id, :thumbnail_exists, :top_keywords, :cluster_group_id
    map_include :top_keywords => :top_keywords_serialize, :stories => :stories_serialize, :image => :image_serialize, :url => :url_serialize
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
    story_group_ids = story_group_ids( *args )
    options = args.extract_options!
    { 
      :select => %Q( story_groups.*, cgm.broadness_score AS broadness_score, cgm.cluster_group_id ),
      :joins => %Q( INNER JOIN cluster_group_memberships AS cgm ON ( cgm.story_group_id = story_groups.id AND cgm.active = #{connection.quoted_true} ) 
        LEFT OUTER JOIN cluster_group_memberships AS cgm2 ON ( cgm2.cluster_group_id = cgm.cluster_group_id AND cgm2.active = #{connection.quoted_true} 
          AND cgm.rank < cgm2.rank AND cgm2.story_group_id IN ( #{ story_group_ids.blank? ? 'NULL' : story_group_ids.join(',') } ) ) ),
      :conditions => [ "cgm.cluster_group_id IN ( :cluster_group_ids ) AND cgm.story_group_id IN ( :story_group_ids )", 
        { :cluster_group_ids => args, :story_group_ids => story_group_ids } ],
      :group => 'cgm.cluster_group_id, cgm.story_group_id',
      :having => "COUNT( cgm2.cluster_group_id ) < #{options[:limit] || 3}",
      :order => 'cgm.rank ASC'
    }
  }
  
  named_scope :by_cluster_group_id, lambda{ |*args|
    options = args.extract_options!
    cluster_group_id = args.first || 'NULL'
    user = options.delete(:user)
    top_cluster_ids = Array( options.delete(:top_cluster_ids) || 0 ).join(',')
    { 
      :select => %Q( story_groups.*, cgm.broadness_score AS broadness_score, cgm.cluster_group_id ),
      :joins => %Q( INNER JOIN cluster_group_memberships AS cgm ON ( cgm.story_group_id = story_groups.id AND cgm.active = #{connection.quoted_true} 
        AND cgm.cluster_group_id = #{ args.first } AND story_groups.id NOT IN ( #{top_cluster_ids} ) ) ),
      :conditions => [ :video, :opinion, :blog ].collect{ |x| vob_sql_value_for( 'story_groups', x, user ) }.select{ |x| !x.nil? }.join( ' AND ' ),
      :order => 'cgm.rank ASC'
    }
  }
  
  named_scope :top_clusters, lambda{ |*args|
    options = args.extract_options!
    options.symbolize_keys!
    options.delete_if{ |k,v| v.blank? }
    user = options.delete(:user)
    if user
      category_ids = MultiValuedPreference.owner( user ).preference( :top_stories_cluster_group ).all( :select => 'value' ).collect( &:value )
      options.reverse_merge!( :region_id => user.preference.region_id, :language_id => user.preference.default_language_id )
    else
      category_ids = Preference.select_all( :top_stories_cluster_group ).collect{ |s| s[:id] }
      options.reverse_merge!( :region_id => Preference.default_region_id, :language_id => Preference.default_language_id )
    end
    cluster_ids = ClusterGroup.region( options[:region_id] ).language( options[:language_id] ).all( :select => 'id', 
      :conditions => { :public => true, :category_id => category_ids } 
    ).collect( &:id )
    cluster_ids.push( 'NULL' ) if cluster_ids.blank?
    { 
      :select => %Q( story_groups.*, cgm.broadness_score AS broadness_score, cgm.cluster_group_id ),
      :joins => %Q( INNER JOIN cluster_group_memberships AS cgm ON ( cgm.story_group_id = story_groups.id AND cgm.active = #{connection.quoted_true} AND 
        cgm.cluster_group_id IN (#{ cluster_ids.join(',') }) ) ),
      :order => 'cgm.broadness_score DESC'
    }
  }
  
  #
  # This function calculates the cluster groups dynamically
  # Should be called by Background Process
  #
  def self.find_each_for_cluster_group( cluster_group, &block)
     source_ids = cluster_group.perspective.source_ids
     find_each( {
        :select => 'story_groups.*, COUNT( DISTINCT source_id ) + ( COUNT( * ) / 100 ) AS broadness_score',
        :joins => 'LEFT OUTER JOIN story_group_memberships AS sgm ON ( sgm.group_id = story_groups.id)',
        :conditions  => { :sgm => { :source_id => source_ids }, 
          :category_id => cluster_group.category_id, 
          :language_id => cluster_group.language_id 
        },
        :group => 'story_groups.id'
      }, &block )
  end
  
  def self.thumbs_hash_map( story_group_ids, user = nil )
    conditions = [ 'image_path_cache IS NOT NULL AND thumb_saved = ?', true ]
    sgs = Story.story_group_ids( *story_group_ids ).all( 
      :select => %Q(stories.id, sgm.group_id),  
      :user => user,
      :conditions => conditions,
      :order => 'sgm.rank ASC'
    ).group_by{ |story| story.read_attribute( :group_id ).to_i }
    story_group_archive_ids = story_group_ids - sgs.keys
    unless story_group_archive_ids.blank?
      sgsa = Story.story_group_archive_ids( *story_group_archive_ids ).all( 
        :select => %Q(stories.id, sgm.group_id),  
        :user => user,
        :conditions => conditions,
        :order => 'sgm.blub_score DESC'
      ).group_by{ |story| story.read_attribute( :group_id ).to_i }
      sgs.merge!( sgsa )
    end
    story_ids = []
    sgs.each_pair do | group, stories |
      story = stories.first
      if story
        sgs[group] = story
        story_ids.push( story.id )
      else
        sgs.delete(group)
      end
    end
    if story_ids
      stories_with_images = Story.all( :select => 'id, image_path_cache, url', :conditions => { :id => story_ids } ).group_by( &:id )
      sgs.each_pair do | group, story |
        if (image_story = stories_with_images[ story.id ].first)
          sgs[group] = { :image_path_cache => image_story.image_path_cache, :url => image_story.url }
        else
          sgs.delete( group )
        end
      end
    end
    story_ids.clear
    stories_with_images.clear
    return sgs
  end
  
  #
  # TODO: Sorted By relevance or time ( Cluster View )
  #
  def self.populate_stories_to_serialize( user, clusters, per_cluster = 3, story_ids_to_skip = [])
    # hash_map is top stories for each story group using personalized score if applicable
    stories_hash_map = Story.hash_map_by_story_groups( clusters.collect( &:id ), user, per_cluster, story_ids_to_skip )
    thumbs_hash_map = StoryGroup.thumbs_hash_map( clusters.collect( &:id ) )
    clusters.each do |cluster| 
      cluster.stories_to_serialize = stories_hash_map[ cluster.id ] || []
      if thumbs_info = thumbs_hash_map[ cluster.id ]
        cluster.image_path_cache = thumbs_info[ :image_path_cache ]
        cluster.url = thumbs_info[ :url ]
      end
    end
    story_ids, source_ids = clusters.inject([[], []]) do | acc, cluster| 
      # cluster.stories_to_serialize ||= Story.personalize_for!( cluster.top_stories, user, user_quality_rating_hash_map )[ 0...per_cluster ]
      cluster.stories_to_serialize.inject(acc){ |aac, story| aac.first.push( story.id ); aac.last.push( story.source_id ); aac }
    end
    source_ids.uniq!
    
    authors_pool = Author.map( story_ids )
    
    sources_pool = Source.find(:all, :conditions => { :id => source_ids }).inject({}){ |map, source| map[source.id] = source; map }
    clusters.each{ |cluster| cluster.authors_pool = authors_pool; cluster.sources_pool = sources_pool }
  end
  
  class << self 
        
    def vob_sql_value_for( table_name, attribute, user )
      return nil unless user
      column_name = "#{table_name}.#{attribute}_count"
      case user.preference.send( attribute ) when 0 : "story_count > #{column_name} + 1" # Atleast Two Stories without preference
      when 4 : "#{column_name} > 1" # Atleast Two Stories with preference
      else nil end
    end
    
    def story_group_ids( *args )
      options = args.extract_options!
      options[:limit] = Integer( options[:limit] || 3 ) rescue 3
      user = options.delete( :user )
      exclude_story_group_ids = options.delete( :exclude_cluster_ids ) || options.delete( :exclude_story_group_ids )
      conditions = [ :video, :opinion, :blog ].collect{ |x| vob_sql_value_for( 'story_groups', x, user ) }.select{ |x| !x.nil? }
      conditions.push( "cgm.cluster_group_id IN ( :cluster_group_ids )")
      conditions_hash = { :cluster_group_ids => args }
      if exclude_story_group_ids.try(:any?)
        conditions.push( "cgm.story_group_id NOT IN ( :story_group_ids )" )
        conditions_hash[ :story_group_ids ] = exclude_story_group_ids
      end
      conditions = sanitize_sql_for_conditions( [ conditions.join(' AND '), conditions_hash ] )
      
      connection.select_values(
        %Q( SELECT GROUP_CONCAT(story_groups.id ORDER BY cgm.rank ASC SEPARATOR ',') AS ids 
          FROM story_groups INNER JOIN cluster_group_memberships AS cgm ON ( cgm.story_group_id = story_groups.id AND cgm.active = #{connection.quoted_true} )
          WHERE #{conditions} GROUP BY cgm.cluster_group_id
        )
      ).inject([]){ |s,group| group.split(',')[ 0, options[:limit] ].inject(s){ |ss, ii| ss.push(ii.to_i) } }
    end
    
  end
  
  protected
  
  def image_serialize( options = {} )
    ( image_path_cache ? "http://cdn.jurnalo.com#{image_path_cache}" : nil ).to_xml( :root => options[:root], :builder => options[:builder], :skip_instruct => true )
  end
  
  def url_serialize( options = {} )
    url.to_xml( :root => options[:root], :builder => options[:builder], :skip_instruct => true )
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
  
  def top_keywords_serialize( options = {} )
    top_keywords.to_xml( options.merge( :children => 'keyword' ) )
  end
  
  def top_stories_serialize( options = {} )
    ( top_stories[0...3] ).to_xml( :set => :short, :root => options[:root], :builder => options[:builder], :skip_instruct=>true, :children => 'story' )
  end
  
end