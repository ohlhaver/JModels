class SourceRegion < ActiveRecord::Base
  belongs_to :region
  belongs_to :source
  validates_presence_of  :source_id, :region_id
end
