class Story < ActiveRecord::Base
  
  attr_accessor :authors_to_serialize
  attr_accessor :source_to_serialize
  attr_accessor :group_to_serialize
  attr_accessor :author_subscription_count
  
  serialize_with_options :short do
    dasherize false
    except :is_opinion, :is_video, :is_blog, :thumb_exists, :feed_id, :subscription_type, :thumbnail_exists, :created_at, :jcrawl_story_id, :delta, :quality_rating
  end
  
  serialize_with_options  do
    dasherize false
    except :delta, :quality_rating, :jcrawl_story_id, :thumbnail_exists, :thumb_exists, :quality_ratings_generated, :author_quality_rating, :source_quality_rating
    map_include :authors => :authors_serialize, :source => :source_serialize, :cluster => :group_serialize
  end
  
  belongs_to :source
  belongs_to :feed
  belongs_to :language

  has_many  :story_authors
  has_many  :authors, :through => :story_authors, :source => :author
  
  # For Sphinx Index Generation
  has_many :ban_quality_ratings,            :class_name => 'StoryUserQualityRating::Ban'
  has_many :author_low_quality_ratings,     :class_name => 'StoryUserQualityRating::AuthorLow'
  has_many :author_normal_quality_ratings,  :class_name => 'StoryUserQualityRating::AuthorNormal'
  has_many :author_high_quality_ratings,    :class_name => 'StoryUserQualityRating::AuthorHigh'
  has_many :source_low_quality_ratings,     :class_name => 'StoryUserQualityRating::SourceLow'
  has_many :source_normal_quality_ratings,  :class_name => 'StoryUserQualityRating::SourceNormal'
  has_many :source_high_quality_ratings,    :class_name => 'StoryUserQualityRating::SourceHigh'
  
  has_one    :story_content
  has_one    :story_metric
  has_one    :story_thumbnail
  
  has_many :story_group_memberships
  has_many :story_groups, :through => :story_group_memberships, :source => :story_group
  
  has_one  :active_story_group_membership, :class_name => 'StoryGroupMembership::Active'
  
  has_one    :thumbnail, :through => :story_thumbnail, :source => :thumbnail

  validates_presence_of    :title, :url, :language_id, :source_id, :feed_id, :created_at, :story_content, :subscription_type, :on => :create
  validates_inclusion_of   :subscription_type, :in => %w(public private paid)
  
  
  before_create :mark_as_opinion_if_author_is_opinion_writer
  after_destroy :delete_dependencies
  after_create :check_and_insert_into_top_author_stories
  
  named_scope :language, lambda { |language| { :conditions => { :language_id => ( language.is_a?( Language ) ? language.id : language ) } } }
  named_scope :since, lambda{ |time|  { :conditions => [ 'stories.created_at > ?', time ] } }
  named_scope :non_duplicates, :conditions => 'stories.id NOT IN ( SELECT story_id FROM story_metrics WHERE master_id IS NOT NULL )'
  named_scope :duplicates, :conditions => 'stories.id IN ( SELECT story_id FROM story_metrics WHERE master_id IS NOT NULL )'
  # last 24 hours Story.since(24.hours.ago).language(Language.find_by_code('de').id)
  
  named_scope :story_group_ids, lambda{ |*args|
    options = args.extract_options!
    {
      :joins => "INNER JOIN story_group_memberships AS sgm ON (sgm.story_id = stories.id)",
      :conditions => { :sgm => { :group_id => args, :master_id => nil } }
    }
  }
  
  named_scope :story_group_archive_ids, lambda{ |*args| 
    options = args.extract_options!
    {
      :joins => "INNER JOIN story_group_membership_archives AS sgm ON (sgm.story_id = stories.id)",
      :conditions => { :sgm => { :group_id => args, :master_id => nil } }
    }
  }
  
  # Used by Background Algorithm to Generate Top Author Stories
  named_scope :with_author_subscription_count, lambda{ 
    { 
      :select => 'stories.*, SUM( IF( ta.subscription_count > 2, 1, 0 ) ) AS top_author_count, MAX( ta.subscription_count ) AS author_subscription_count',
      :joins => ' INNER JOIN story_authors ON ( story_authors.story_id = stories.id ) 
        INNER JOIN bg_top_authors AS ta ON ( ta.author_id = story_authors.author_id ) ',
      :group => 'stories.id',
      :having => 'top_author_count > 0'
    }
  }
  
  # Used by Frontend Query to fetch top authors
  named_scope :by_top_authors, lambda {
    { :select => 'stories.*, tas.subscription_count AS author_subscription_count', 
      :joins => "INNER JOIN bg_top_author_stories AS tas ON ( tas.story_id = stories.id AND tas.active = #{connection.quoted_true})", 
      :order => 'tas.subscription_count DESC, stories.created_at DESC' }
  }
  
  # particular story
  def duplicates( *args )
    master_id = story_metric ? story_metric.master_id : id
    master_id ||= id
    self.class.send(:with_scope, :find => { 
        :conditions => 
          [ '( stories.id IN ( SELECT story_id FROM story_metrics 
              WHERE master_id = ? ) OR stories.id = ? ) AND stories.id != ? ', master_id, master_id, id ] 
      }
    ) do
      self.class.find( *args )
    end
  end
  
  define_index do
    # We need to index last month's stories for search
    where 'stories.created_at >= DATE_SUB( UTC_TIMESTAMP(), INTERVAL 1 MONTH )'
    indexes :title, :as => :title, :sortable => true
    indexes story_content(:body), :as => :content
    indexes story_authors.author(:name), :as => :authors
    
    # Attributes over which search results can be limited
    has :id, :as => :story_id
    has :created_at
    has :is_video, :facet => true
    has :is_blog, :facet => true
    has :is_opinion, :facet => true
    has "CASE subscription_type WHEN 'public' THEN 0 WHEN 'private' THEN 1 ELSE 2 END", :type => :integer, :as => :subscription_type
    has :feed_id
    has :source_id
    has :language_id, :facet => true
    has "COALESCE(stories.quality_rating, 1)", :type => :integer, :as => :quality_rating
    has "COALESCE(stories.author_quality_rating, -1)", :type => :float, :as => :default_author_rating
    has "COALESCE(stories.source_quality_rating, -1)", :type => :float, :as => :default_source_rating
    has story_metric(:master_id), :as => :master_id
    has story_authors(:author_id), :as => :author_ids
    has active_story_group_membership(:group_id), :as => :group_id, :type => :integer, :facet => true
    has "CRC32( IFNULL( CONCAT( 'GROUP', active_story_group_memberships.group_id ), CONCAT('STORY', stories.id ) ) )", :as => :cluster_id, :type => :integer
    
    # User Specific Quality Ratings
    has ban_quality_ratings( :user_id ),           :as => :ban_user_ids,            :source => :query
    has author_low_quality_ratings( :user_id ),    :as => :author_low_user_ids,     :source => :query
    has author_normal_quality_ratings( :user_id ), :as => :author_normal_user_ids,  :source => :query
    has author_high_quality_ratings( :user_id ),   :as => :author_high_user_ids,    :source => :query
    has source_low_quality_ratings( :user_id ),    :as => :source_low_user_ids,     :source => :query
    has source_normal_quality_ratings( :user_id ), :as => :source_normal_user_ids,  :source => :query
    has source_high_quality_ratings( :user_id ),   :as => :source_high_user_ids,    :source => :query
    
    set_property :delta => :delayed
    set_property :field_weights => {
      :title     => 3,
      :content   => 1,
      :authors   => 1.5
    }
  end
  
  # To overcome thinking sphinx bug where deleted item is not flagged from story_core index
  unless respond_to?( :destroy_with_ts_bugfix )
    def destroy_with_ts_bugfix
      update_attribute( :delta, true )
      destroy_without_ts_bugfix
    end
    alias_method_chain :destroy, :ts_bugfix
  end
  
  def author_subscription_count
    write_attribute( :author_subscription_count, authors.collect( &:subscription_count ).max ) unless has_attribute?( :author_subscription_count ) 
    Integer( read_attribute( :author_subscription_count ) )
  end
  
  def by_top_author?
    authors.select( &:top_author? ).any?
  end
  
  def delete_dependencies
    StoryMetric.delete_all( { :story_id => self.id } )
    StoryContent.delete_all( { :story_id => self.id } )
    StoryAuthor.delete_all( { :story_id => self.id } )
    StoryThumbnail.delete_all( { :story_id => self.id } )
    StoryGroupMembership.delete_all( { :story_id => self.id } )
  end
  
  def self.insert_into_top_author_stories( story_id, subscription_count, active = false)
    if active
      connection.execute( "INSERT INTO bg_top_author_stories (story_id, subscription_count, active ) VALUES ( #{story_id}, #{subscription_count}, #{connection.quoted_true})" )
    else
      connection.execute( "INSERT INTO bg_top_author_stories (story_id, subscription_count) VALUES( #{story_id}, #{subscription_count} )")
    end rescue nil
  end
  
  #
  # Personalize an array of stories according to user preferences
  #
  def self.personalize_for!( stories, user, user_quality_rating_hash_map = nil )
    return stories if stories.blank? || user.blank?
    user_quality_rating_hash_map ||= StoryUserQualityRating.hash_map( user, stories.collect(&:id) )
    return stories if user_quality_rating_hash_map.blank?
    ref = Time.now
    stories.each do |story| 
      story.score = story.age_value( ref ) * ( user_quality_rating_hash_map[ story.id ] || story.quality_rating || 1 ) * 
        story.vob_value_for( :blog, user ) * story.vob_value_for( :video, user ) * 
        story.vob_value_for( :opinion, user ) * story.subscription_value_for( user )
    end
    stories.delete_if{ |story| story.without_score? }
    stories.sort!
    return stories
  end
  
  def score=(value)
    write_attribute(:blub_score, value)
  end
  
  def score
    Float( read_attribute( :blub_score ) ) rescue 0.0
  end
  
  def without_score?
    score.zero?
  end
  
  def <=>( story )
    story.score <=> self.score
  end
  
  # SQL Expressions Used To Generate Dynamic Query to Include User Preferences
  class << self 
        
    def vob_sql_value_for( attribute, user )
      column_name = "is_#{attribute}"
      case user.preference.send( attribute ) when 0 : "IF( stories.#{column_name}, 0, 1 )"
      when 1 : "IF( stories.#{column_name}, 0.5, 2 )"
      when 3 : "IF( stories.#{column_name}, 2, 0.5 )"
      when 4 : "IF( stories.#{column_name}, 1, 0 )"
      else "1"
      end
    end

    def subscription_sql_value_for( user )
      case( user.preference.subscription_type ) when 1 : "IF( stories.subscription_type = 'public', 1, IF( stories.subscription_type = 'private', 1, 0 ) )"
      when 2 : "IF( stories.subscription_type= 'public', 1, 0 )"
      else "1" end
    end

    def age_sql_value
      "( 100 / POW(1 + IF( UTC_TIMESTAMP() > stories.created_at, TIMESTAMPDIFF(HOUR, stories.created_at, UTC_TIMESTAMP()),  0 ), 0.33 ) )"
    end
    
    def hash_map_by_story_groups( story_group_ids, user = nil, per_cluster = 3, story_ids_to_skip = [] )
      conditions = story_ids_to_skip.blank? ? nil : [ 'stories.id NOT IN (?)', story_ids_to_skip ]
      sgs = story_group_ids( *story_group_ids ).all( 
        :select => %Q(stories.id, sgm.group_id),  
        :user => user,
        :conditions => conditions,
        :order => 'sgm.rank ASC'
      ).group_by{ |story| story.read_attribute( :group_id ).to_i }
      story_group_archive_ids = story_group_ids - sgs.keys
      unless story_group_archive_ids.blank?
        sgsa = story_group_archive_ids( *story_group_archive_ids ).all( 
          :select => %Q(stories.id, sgm.group_id),  
          :user => user,
          :conditions => conditions,
          :order => 'sgm.rank ASC'
        ).group_by{ |story| story.read_attribute( :group_id ).to_i }
        sgs.merge!( sgsa )
      end
      story_ids = []
      sgs.each_pair do | group, stories |
        ( sgs[group] = stories[0, per_cluster] ).inject( story_ids ){ |acc,s| acc.push( s.id ) }
      end
      full_stories = Story.all( :conditions => { :id => story_ids } ).group_by( &:id )
      sgs.each_pair do | group, stories |
        stories.collect!{ |story| 
          final_story = full_stories[ story.id ].first
          final_story.score = story.score
          final_story
        }
      end
      full_stories.clear
      return sgs
    end
    
    #
    # pass the user record to personalize the find results :user => user_object
    #
    def find_with_personalize( *args )
      options = args.extract_options!
      user = options.delete(:user) || options.delete('user')
      if user
        score_statement = age_sql_value.dup
        score_statement << "*COALESCE( story_user_quality_ratings.quality_rating, COALESCE( stories.quality_rating, 1) )"
        score_statement << "*#{vob_sql_value_for( :video, user )}"
        score_statement << "*#{vob_sql_value_for( :opinion, user )}"
        score_statement << "*#{vob_sql_value_for( :blog, user )}"
        score_statement << "*#{subscription_sql_value_for( user )}"
        score_conditions  = "COALESCE( story_user_quality_ratings.quality_rating, COALESCE( stories.quality_rating, 1) ) > 0"
        score_conditions << " AND #{vob_sql_value_for( :video, user )} > 0"
        score_conditions << " AND #{vob_sql_value_for( :opinion, user )} > 0"
        score_conditions << " AND #{vob_sql_value_for( :blog, user )} > 0"
        score_conditions << " AND #{subscription_sql_value_for( user )} > 0"
        options[:select] ||= "stories.*"
        options[:select] << ", (#{score_statement}) AS blub_score"
        options[:order] = [ 'blub_score DESC', options[:order] ].select{ |x| !x.blank? }.join(', ')
        personalize_options = { 
          :joins => %Q(LEFT JOIN story_user_quality_ratings ON ( story_user_quality_ratings.story_id = stories.id AND story_user_quality_ratings.user_id = #{user.id} ) ),
          :conditions => "( #{score_conditions} )"
        }
        with_scope :find => personalize_options do 
          find_without_personalize( *args.push( options ) )
        end
      else
        find_without_personalize( *args.push( options ) )
      end
    end
    
    #
    # pass the user record to count the personalized stories for user
    #
    def count_with_personalize( *args )
      options = args.extract_options!
      user = options.delete(:user) || options.delete('user')
      if user
        score_conditions  = "COALESCE( story_user_quality_ratings.quality_rating, COALESCE( stories.quality_rating, 1) ) > 0"
        score_conditions << " AND #{vob_sql_value_for( :video, user )} > 0"
        score_conditions << " AND #{vob_sql_value_for( :opinion, user )} > 0"
        score_conditions << " AND #{vob_sql_value_for( :blog, user )} > 0"
        score_conditions << " AND #{subscription_sql_value_for( user )} > 0"
        personalize_options = {
          :joins => %Q(LEFT JOIN story_user_quality_ratings ON ( story_user_quality_ratings.story_id = stories.id AND story_user_quality_ratings.user_id = #{user.id} ) ),
          :conditions => "( #{score_conditions} )"
        }
        with_scope :find => personalize_options do
          count_without_personalize( *args.push( options ) )
        end
      else
        count_without_personalize( *args.push( options ) )
      end
    end
    
    alias_method_chain :find, :personalize
    alias_method_chain :count, :personalize
  end
  
  protected
  
  def mark_as_opinion_if_author_is_opinion_writer
    return if self.is_opinion?
    self.is_opinion = self.authors.inject( false ){ | opinion, author |  opinion ||=  author.is_opinion? }
    return true
  end
  
  def age_value( ref = Time.now )
    diff = ref > created_at ? (ref - created_at).to_f : 0.0
    diff_in_hours = ( diff / 3600 ).to_i
    100 / ( ( 1 + diff_in_hours ) ** 0.33 )
  end
  
  def subscription_value_for( user )
    case( user.preference.subscription_type ) when 1 : subscription_type == 'public' || subscription_type ==  'private' ? 1 : 0
    when 2 : subscription_type == 'public' ? 1 : 0 
    else 1 end
  end
  
  def vob_value_for( attribute, user )
    value_on = send("is_#{attribute}?")
    case( user.preference.send( attribute ) ) when 0: value_on ? 0 : 1
    when 1: value_on ? 0.5 : 2
    when 3: value_on ? 2 : 0.5
    when 4: value_on ? 1 : 0
    else 1 end
  end
  
  def find_or_initialize_story_metric
    self.story_metric ||= StoryMetric.new
  end
  
  def authors_serialize( options = {} )
    ( self.authors_to_serialize || self.authors ).to_xml( :set => :short , :root => options[:root], :builder => options[:builder], :skip_instruct=>true )
  end
  
  def source_serialize( options = {} )
    ( self.source_to_serialize || self.source ).to_xml( :set => :short, :root => options[:root], :builder => options[:builder], :skip_instruct => true )
  end
  
  def group_serialize( options = {} )
    self.group_to_serialize.to_xml( :root => options[:root], :builder => options[:builder], :skip_instruct => true )
  end
  
  # Based on list of current top authors
  def check_and_insert_into_top_author_stories
    return if self.created_at < 24.hours.ago || !self.by_top_author?
    self.class.insert_into_top_author_stories( self.id, self.author_subscription_count, true )
  end
  
end
