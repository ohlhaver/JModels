class SourceRegion < ActiveRecord::Base
  belongs_to :region
  belongs_to :source
  validates_presence_of  :source_id, :region_id
  validates_uniqueness_of :source_id, :scope => :region_id
  set_primary_keys :source_id, :region_id
end
