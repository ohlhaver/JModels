class CreatePriorityAuthors < ActiveRecord::Migration
  def self.up
    create_table :priority_authors, :id => false do |t|
      t.integer :author_id
      t.boolean :checked
      t.timestamp :last_checked_at
      t.timestamp :updated_at
    end
    add_index :priority_authors, :author_id, :unique => true
    add_index :priority_authors, [ :checked, :updated_at, :author_id ], :unique => true
  end

  def self.down
    drop_table :priority_authors
  end
end
