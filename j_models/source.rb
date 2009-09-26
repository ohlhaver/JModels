require 'j_models/source_region'
class Source < ActiveRecord::Base
  has_many :source_regions
  has_many :regions, :through => :source_regions, :source => :region
  
  has_many :feeds
end
