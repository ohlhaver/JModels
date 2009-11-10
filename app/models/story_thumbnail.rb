class StoryThumbnail < ActiveRecord::Base
  belongs_to  :story
  belongs_to  :thumbnail
end
