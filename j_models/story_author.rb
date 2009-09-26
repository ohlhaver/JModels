class StoryAuthor < ActiveRecord::Base
  belongs_to  :story
  belongs_to  :author
end
