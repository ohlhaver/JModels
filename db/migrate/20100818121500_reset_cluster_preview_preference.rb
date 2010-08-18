class ResetClusterPreviewPreference < ActiveRecord::Migration
  def self.up
    User.find_each( :include => :preference ){ |u|
      u.preference.update_attribute(:cluster_preview, 1)
      u.touch
    }
  end

  def self.down
  end
end
