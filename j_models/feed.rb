class Feed < ActiveRecord::Base
  belongs_to :source
  belongs_to :subscription_type
  belongs_to :language
  has_many   :feed_categories
  has_many   :categories, :through => :feed_categories, :source => :category
end
