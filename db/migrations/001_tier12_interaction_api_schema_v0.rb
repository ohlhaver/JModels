class Tier12InteractionApiSchemaV0 < ActiveRecord::Migration

  def self.up
    create_table :languages do |t|
      t.string :name, :null => false, :default => '', :limit => 50
      t.string :code, :null => false, :default => '', :limit => 10
    end
    add_index :languages, [:code], :name => "index_languages_on_code", :unique => true

    create_table :regions do |t|
      t.string :name, :null => false, :default => '', :limit => 50
      t.string :code, :null => false, :default => '', :limit => 10
    end
    add_index :regions, [:code], :name => "index_regions_on_code", :unique => true

    create_table :categories do |t|
      t.string :name, :null => false, :default => '', :limit => 50
      t.string :code, :null => false, :default => '', :limit => 10
    end
    add_index :categories, [:code], :name => "index_categories_on_code", :unique => true

    create_table :sources do |t|
      t.string  :name,               :null => false, :default => '', :limit => 100 
      t.string  :url,                :null => false, :default => '', :limit => 1000
      t.string  :subscription_type,  :null => false, :default => 'public', :limit => 10
    end

    create_table :source_regions, {:id => false} do |t|
      t.integer :source_id, :null => false, :default => 0
      t.integer :region_id, :null => false, :default => 0
    end

    add_index :source_regions, [:source_id], :name => "index_source_regions_on_source_id"
    add_index :source_regions, [:region_id], :name => "index_source_regions_on_region_id"


    create_table :feeds do |t|
      t.string  :url,                  :null => false, :default => '', :limit => 1000 
      t.string  :publication,          :null => false, :default => '', :limit => 255  
      t.string  :website,              :null => false, :default => '', :limit => 255  
      t.boolean :is_opinion,           :null => false, :default => 0
      t.boolean :is_video,             :null => false, :default => 0
      t.boolean :is_blog,              :null => false, :default => 0
      t.string  :subscription_type,    :null => false, :default => 'public', :limit => 10
      t.integer :language_id,          :null => false, :default => 0
      t.integer :source_id,            :null => false, :default => 0
    end

    add_index :feeds, [:source_id], :name => "index_feeds_on_source_id"

    create_table :feed_categories, {:id => false} do |t|
      t.integer :feed_id,     :null => false, :default => 0
      t.integer :category_id, :null => false, :default => 0
    end

    add_index :feed_categories, [:feed_id],     :name => "index_feed_categories_on_feed_id"
    add_index :feed_categories, [:category_id], :name => "index_feed_categories_on_category_id"

    create_table :stories do |t|
      t.string  :title,       :null => false, :default => '', :limit => 1000
      t.string  :url,         :null => false, :default => '', :limit => 1000
      t.boolean :is_opinion,  :null => false, :default => 0
      t.boolean :is_video,    :null => false, :default => 0
      t.boolean :is_blog,     :null => false, :default => 0
      t.integer :language_id, :null => false, :default => 0
      t.integer :source_id,   :null => false, :default => 0
      t.integer :feed_id,     :null => false, :default => 0
    end

    add_index :stories, [:source_id],   :name => "index_stories_on_source_id"
    add_index :stories, [:feed_id],     :name => "index_stories_on_feed_id"
    add_index :stories, [:language_id], :name => "index_stories_on_language_id"

    create_table :story_contents, {:id => false} do |t|
      t.integer :story_id, :null => false, :default => 0
      t.text    :body
    end

    add_index :story_contents, [:story_id], :name => "index_story_contents_on_story_id"

    create_table :authors do |t|
      t.string  :name,      :null => false, :default => '', :limit => 100
      t.boolean :is_agency, :null => false, :default => 0
    end
    add_index :authors, [:name], :name => "index_authors_on_name", :unique => true
    
    create_table :story_authors, {:id => false} do |t|
      t.integer :story_id,  :null => false, :default => 0
      t.integer :author_id, :null => false, :default => 0
    end

    add_index :story_authors, [:story_id],   :name => "index_story_authors_on_story_id"
    add_index :story_authors, [:author_id],   :name => "index_story_authors_on_author_id"
    create_table :agencies do |t|
      t.integer :author_id, :null => false, :default => 0 
    end
    add_index :agencies, [:author_id], :name => "index_agencies_on_author_id"

    
    create_table :thumbnails do |t|
      t.string  :content_type, :null => false, :default => '', :limit => 100
      t.integer :height,       :null => false, :default => 0
      t.integer :width,        :null => false, :default => 0
      t.integer :source_id,    :null => false, :default => 0
    end
    add_index :thumbnails, [:source_id], :name => "index_thumbnails_on_source_id"

    create_table :story_thumbnails, {:id => false} do |t|
      t.integer :story_id,     :null => false, :default => 0
      t.integer :thumbnail_id, :null => false, :default => 0
    end  

    add_index :story_thumbnails, [:story_id],     :name => "index_story_thumbnails_on_story_id"
    add_index :story_thumbnails, [:thumbnail_id], :name => "index_story_thumbnails_on_thumbnail_id"

    ##create_table :story_qualities do |t|
    ##end

    ##create_table :story_keywords do |t|
    ##end

    ##create_table :groups do |t|
    ##end

    ##create_table :story_groups do |t|
    ##end

    ##create_table :group_region_ranks do |t|
    ##end
  end

  def self.down
  end
end
