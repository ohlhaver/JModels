class FeedCategory < ActiveRecord::Base
  belongs_to :feed
  belongs_to :category
  
  set_primary_keys :feed_id, :category_id
end
