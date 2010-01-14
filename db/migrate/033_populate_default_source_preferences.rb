class PopulateDefaultSourcePreferences < ActiveRecord::Migration
  def self.up
    Source.find_each do |source|
      source.default_preference ||= 1
      source.save
    end
  end

  def self.down
  end
end
