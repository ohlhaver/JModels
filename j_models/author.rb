class Author < ActiveRecord::Base
  has_many  :story_authors
  has_many  :stories, :through => :story_authors, :source => :story
end
