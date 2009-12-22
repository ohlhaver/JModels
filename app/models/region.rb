class Region < ActiveRecord::Base
  validates_presence_of   :id, :name, :code
  validates_uniqueness_of :code
  
  has_many :source_regions
  has_many :sources, :through => :source_regions, :source => :source
  
  def self.for_select( reload = false )
    @@regions_for_select = nil if reload
    @@regions_for_select ||= self.all( :select => 'id, name' ).collect{ |x| [ x.name, x.id ] }
  end
  
end
