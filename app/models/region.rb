class Region < ActiveRecord::Base
  
  unless defined?( DefaultLanguage)
    DefaultLanguage = {
      'DE' => 'de',
      'CH' => 'de',
      'AT' => 'de'
    }
  end
  
  validates_presence_of   :id, :name, :code
  validates_uniqueness_of :code
  
  has_many :source_regions
  #has_many :sources, :through => :source_regions, :source => :source
  
  has_many :sources, :finder_sql => 'SELECT * FROM sources LEFT OUTER JOIN source_regions ON ( source_regions.source_id = sources.id )
    WHERE #{id} = -1 OR source_regions.region_id = #{id} GROUP BY sources.id'
    
  def self.for_select( reload = false )
    @@regions_for_select = nil if reload
    @@regions_for_select ||= self.all( :select => 'id, name' ).collect{ |x| [ x.name, x.id ] }
  end
  
  def default_language_code
    DefaultLanguage[ self.code ] || 'en'
  end
  
end
