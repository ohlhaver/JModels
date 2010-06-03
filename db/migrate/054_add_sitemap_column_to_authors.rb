class AddSitemapColumnToAuthors < ActiveRecord::Migration
  def self.up
    add_column :authors, :sitemap, :boolean, :default => '0'
    add_index :authors, [ :sitemap, :block ], :name => 'authors_sitemap_idx'
  end

  def self.down
    remove_index :authors, :name => 'authors_sitemap_idx'
    remove_column :authors, :sitemap
  end
end
