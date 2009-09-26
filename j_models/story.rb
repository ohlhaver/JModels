class Story < ActiveRecord::Base
  belongs_to :source
  belongs_to :feed
  belongs_to :language

  has_many  :story_authors
  has_many  :authors, :through => :story_authors, :source => :author

  
  has_one    :story_content 
  has_many   :story_thumbnails
  has_one    :thumbnail, :through => :story_thumbnails, :source => :thumbnail
end
