class Story < ActiveRecord::Base
  belongs_to :source
  belongs_to :feed
  belongs_to :language

  has_many  :story_authors
  has_many  :authors, :through => :story_authors, :source => :author

  
  has_one    :story_content 

  has_one    :story_thumbnail
  has_one    :thumbnail, :through => :story_thumbnail, :source => :thumbnail


  validates_presence_of    :title, :url, :language_id, :source_id, :feed_id, :created_at, :story_content, :subscription_type, :on => :create
  validates_inclusion_of   :subscription_type, :in => %w(public private paid)
end
