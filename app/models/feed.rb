class Feed < ActiveRecord::Base
  belongs_to :source
  belongs_to :language
  has_many   :feed_categories
  
  has_many   :categories, :through => :feed_categories, :source => :category

  validates_presence_of    :id, :url, :subscription_type, :language_id, :source_id
  validates_uniqueness_of  :id, :on => :create
  validates_inclusion_of   :subscription_type, :in => %w(public private paid)
  validates_inclusion_of   :is_opinion, :in => [true,false]
  validates_inclusion_of   :is_blog, :in => [true,false]
  validates_inclusion_of   :is_video, :in => [true,false]
end
