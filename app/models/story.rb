class Story < ActiveRecord::Base
  
  attr_accessor :authors_to_serialize
  attr_accessor :author_subscription_count
  
  serialize_with_options :short do
    dasherize false
    except :is_opinion, :is_video, :is_blog, :thumb_exists, :feed_id, :subscription_type, :thumbnail_exists, :created_at, :jcrawl_story_id, :delta, :quality_rating
  end
  
  serialize_with_options  do
    dasherize false
    except :delta, :quality_rating, :jcrawl_story_id, :thumbnail_exists, :thumb_exists
    map_include :authors => :authors_serialize
  end
  
  belongs_to :source
  belongs_to :feed
  belongs_to :language

  has_many  :story_authors
  has_many  :authors, :through => :story_authors, :source => :author
  
  has_one    :story_content
  has_one    :story_metric
  has_one    :story_thumbnail
  
  has_one  :story_group_membership, :order => 'bj_session_id DESC'
  has_one  :story_group, :through => :story_group_membership, :source => :story_group
  
  has_many :story_group_memberships
  has_many :story_groups, :through => :story_group_memberships, :source => :story_group
  
  has_one    :thumbnail, :through => :story_thumbnail, :source => :thumbnail

  validates_presence_of    :title, :url, :language_id, :source_id, :feed_id, :created_at, :story_content, :subscription_type, :on => :create
  validates_inclusion_of   :subscription_type, :in => %w(public private paid)
  
  after_destroy :delete_dependencies
  after_create :check_and_insert_into_top_author_stories
  
  named_scope :language, lambda { |language| { :conditions => { :language_id => ( language.is_a?( Language ) ? language.id : language ) } } }
  named_scope :since, lambda{ |time|  { :conditions => [ 'stories.created_at > ?', time ] } }
  named_scope :non_duplicates, :conditions => 'stories.id NOT IN ( SELECT story_id FROM story_metrics WHERE master_id IS NOT NULL )'
  named_scope :duplicates, :conditions => 'stories.id IN ( SELECT story_id FROM story_metrics WHERE master_id IS NOT NULL )'
  # last 24 hours Story.since(24.hours.ago).language(Language.find_by_code('de').id)
  
  # Used by Background Algorithm to Generate Top Author Stories
  named_scope :with_author_subscription_count, lambda{ 
    { 
      :select => 'stories.*, SUM( IF( ta.subscription_count > 2, 1, 0 ) ) AS top_author_count, SUM( ta.subscription_count ) AS author_subscription_count',
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
    indexes :title, :as => :title, :sortable => true
    indexes story_content(:body), :as => :content
    indexes story_authors.author(:name), :as => :authors
    # Attributes over which search results can be limited
    has :id, :as => :story_id
    has :created_at
    has :is_video
    has :is_blog
    has :is_opinion
    has "CASE subscription_type WHEN 'public' THEN 0 WHEN 'private' THEN 1 ELSE 2 END", :type => :integer, :as => :subscription_type
    has :feed_id
    has :source_id
    has :language_id
    has "COALESCE(stories.quality_rating, 1)", :type => :integer, :as => :quality_rating
    has story_authors(:author_id), :as => :author_ids
    has story_metric(:master_id), :as => :master_id
    has story_group_membership(:group_id), :as => :group_id
    set_property :delta => :delayed
  end
  
  # To overcome thinking sphinx bug where deleted item is not flagged from story_core index
  unless respond_to?( :destroy_with_ts_bugfix )
    def destroy_with_ts_bugfix
      update_attribute( :delta, true )
      destroy_without_ts_bugfix
    end
    alias_method_chain :destroy, :ts_bugfix
  end
  
  # def mark_duplicate( master_id )
  #   master_id = nil if master_id.to_i == id.to_i
  #   find_or_initialize_story_metric
  #   story_metric.master_id = master_id
  #   story_metric.save if story_metric.changed? || story_metric.new_record?
  # end
  # 
  # def mark_keyword_exists
  #   find_or_initialize_story_metric
  #   story_metric.keyword_exists = true
  #   story_metric.save if story_metric.changed? || story_metric.new_record?
  # end
  # 
  # def keyword_exists?
  #   story_metric && story_metric.keyword_exists?
  # end
  
  def author_subscription_count
    write_attribute( :author_subscription_count, authors.collect( &:subscription_count ).sum ) unless has_attribute?( :author_subscription_count ) 
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
  
  protected
  
  def find_or_initialize_story_metric
    self.story_metric ||= StoryMetric.new
  end
  
  def authors_serialize( options = {} )
    (authors_to_serialize || authors).to_xml( :set => :short , :root => options[:root], :builder => options[:builder], :skip_instruct=>true )
  end
  
  # Based on list of current top authors
  def check_and_insert_into_top_author_stories
    return if self.created_at < 24.hours.ago || !self.by_top_author?
    self.class.insert_into_top_author_stories( self.id, self.author_subscription_count, true )
  end
  
end
