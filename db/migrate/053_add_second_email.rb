class AddSecondEmail < ActiveRecord::Migration
  def self.up
    add_column :users, :second_email, :string
  end

  def self.down
    remove_column :users, :second_email
  end
end
