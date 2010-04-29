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
  
  def self.create_cluster_groups_for( region_codes, language_codes = [ 'de', 'en' ] )
    user = User.find( :first, :conditions => { :login => 'jadmin' } )
    return false unless user
    Region.find(:all, :conditions => { :code => region_codes } ).each do |region|
      Language.find(:all, :conditions => { :code => language_codes } ).each do |language|
        Category.find(:all).each do |category|
          cg = ClusterGroup.create( :name => category.name, :owner => user, :public => true, :perspective => region, :category => category, :language => language )
          if category.default? & !cg.new_record?
            MultiValuedPreference.preference( :homepage_clusters ).create( :tag => "#{region.class.name}:#{region.id}:#{language.id}", :value => cg.id, :owner => user )
          end
        end
      end
    end
    return true
  end
  
  def self.for_select( reload = false )
    @@regions_for_select = nil if reload
    @@regions_for_select ||= self.all( :select => 'id, name' ).collect{ |x| [ x.name, x.id ] }
  end
  
  def default_language_code
    DefaultLanguage[ self.code ] || 'en'
  end
  
end