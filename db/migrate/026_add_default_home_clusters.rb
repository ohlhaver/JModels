class AddDefaultHomeClusters < ActiveRecord::Migration
  
  def self.up
    r = Region.new( :name => 'INTERNATIONAL', :code => 'INT' )
    r.id = -1
    r.save
    
    user = User.find( :first, :conditions => { :login => 'jadmin' } ) || User.find(:first)
    raise 'JAdmin User Donot Exists' unless user
    
    Region.find(:all, :conditions => { :code => [ 'DE', 'CH', 'AT', 'INT' ] } ).each do |region|
      Language.find(:all, :conditions => { :code => [ 'de', 'en' ] } ).each do |language|
        Category.find(:all).each do |category|
          cg = ClusterGroup.create( 
            :name => category.name, :owner => user, :public => true, :perspective => region, :category => category, :language => language )
          if category.default? & !cg.new_record?
            MultiValuedPreference.preference( :homepage_clusters ).create( :tag => "#{region.class.name}:#{region.id}:#{language.id}", :value => cg.id, :owner => user )
          end
        end
      end
    end
  end
  
  def self.down
    ClusterGroup.delete_all
    MultiValuedPreference.preference( :homepage_clusters ).each{ |x| x.destroy }
  end
  
end