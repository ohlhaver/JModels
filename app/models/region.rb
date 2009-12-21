class Region < ActiveRecord::Base
  validates_presence_of   :id, :name, :code
  validates_uniqueness_of :code
  
  has_many :source_regions
  has_many :sources, :through => :source_regions, :source => :source
end
