class SourceRegion < ActiveRecord::Base
  belongs_to :region
  belongs_to :source
end
