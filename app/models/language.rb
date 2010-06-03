class Language < ActiveRecord::Base
    
  validates_presence_of   :name, :code
  validates_uniqueness_of :code
  
  DefaultRegion = {
    'de' => 'DE'
  }
  
  def default_region_code
    DefaultRegion[ self.code ] || 'INT'
  end
  
  def default_edition
    "#{default_region_code.downcase}-#{self.code}"
  end
  
end
