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
  
  define_index do
    indexes :title, :as => :title
    indexes story_content(:body), :as => :content
    indexes story_authors.author(:name), :as => :authors
    # Attributes over which search results can be limited
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
  
end
