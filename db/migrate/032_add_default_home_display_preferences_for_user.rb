class AddDefaultHomeDisplayPreferencesForUser < ActiveRecord::Migration
  def self.up
    User.find_each do |user|
      user.send( :set_user_preference )
      user.preference.send( :create_homepage_box_prefs ) if !user.preference.new_record? && user.multi_valued_preferences.preference( :homepage_boxes ).count.zero?
      user.preference.send( :create_top_section_prefs ) if !user.preference.new_record?
      user.save
    end
  end

  def self.down
  end
end
