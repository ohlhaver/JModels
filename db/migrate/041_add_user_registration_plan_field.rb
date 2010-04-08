class AddUserRegistrationPlanField < ActiveRecord::Migration
  def self.up
    add_column :users, :show_upgrade_page, :boolean
  end

  def self.down
    remove_column :users, :show_upgrade_page
  end
end
