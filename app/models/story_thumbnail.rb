class StoryThumbnail < ActiveRecord::Base
  
  set_primary_key :story_id
  
  belongs_to  :story
  belongs_to  :thumbnail
end
