class Thumbnail < ActiveRecord::Base
  belongs_to  :source
  validates_presence_of  :content_type, :source_id, :height, :width, :download_url, :on => :create
end
