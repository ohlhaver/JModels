class Story < ActiveRecord::Base
  
  belongs_to :source
  belongs_to :feed
  belongs_to :language

  has_many  :story_authors
  has_many  :authors, :through => :story_authors, :source => :author
  
  has_one    :story_content
  has_one    :story_metric
  has_one    :story_thumbnail
  
  has_one    :thumbnail, :through => :story_thumbnail, :source => :thumbnail

  validates_presence_of    :title, :url, :language_id, :source_id, :feed_id, :created_at, :story_content, :subscription_type, :on => :create
  validates_inclusion_of   :subscription_type, :in => %w(public private paid)
  
  after_destroy :delete_dependencies
  
  named_scope :language, lambda { |language| { :conditions => { :language_id => ( language.is_a?( Language ) ? language.id : language ) } } }
  named_scope :since, lambda{ |time|  { :conditions => [ 'stories.created_at > ?', time ] } }
  named_scope :non_duplicates, :conditions => 'stories.id NOT IN ( SELECT story_id FROM story_metrics WHERE master_id IS NOT NULL )'
  named_scope :duplicates, :conditions => 'stories.id IN ( SELECT story_id FROM story_metrics WHERE master_id IS NOT NULL )'
  # last 24 hours Story.since(24.hours.ago).language(Language.find_by_code('de').id)  
  
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
    has :subscription_type
    has :feed_id
    has :source_id
    has :language_id
    has story_authors(:author_id), :as => :author_ids
    has story_metric(:master_id), :as => :master_id
    set_property :delta => :delayed
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
  
  def delete_dependencies
    StoryMetric.delete_all( { :story_id => self.id } )
    StoryContent.delete_all( { :story_id => self.id } )
    StoryAuthor.delete_all( { :story_id => self.id } )
    StoryThumbnail.delete_all( { :story_id => self.id } )
    StoryGroupMembership.delete_all( { :story_id => self.id } )
  end
  
  protected
  
  def find_or_initialize_story_metric
    self.story_metric ||= StoryMetric.new
  end
  
end
