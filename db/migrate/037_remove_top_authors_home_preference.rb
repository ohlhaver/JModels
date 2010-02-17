class RemoveTopAuthorsHomePreference < ActiveRecord::Migration
  def self.up
    MultiValuedPreference.preference( :homepage_boxes ).all( :conditions => { :value => 2 } ).each do |mvp|
      mvp.destroy
    end
  end

  def self.down
  end
end
