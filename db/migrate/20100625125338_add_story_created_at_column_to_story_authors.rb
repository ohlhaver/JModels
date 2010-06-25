class AddStoryCreatedAtColumnToStoryAuthors < ActiveRecord::Migration
  def self.up
    add_column :story_authors, :story_created_at, :timestamp
    add_index :story_authors, :story_created_at, :name => 'story_authors_created_at_index_1'
    add_index :story_authors, [ :author_id, :story_created_at ], :name => 'story_authors_created_at_index_2'
    StoryAuthor.each_story{ |story, story_id|
      if story
        puts story.id
        StoryAuthor.update_all( { :story_created_at => story.created_at }, { :story_id => story.id } )
      else
        StoryAuthor.delete_all( { :story_id => story_id } )
      end
    }
  end

  def self.down
    remove_index :story_authors, :name => 'story_authors_created_at_index_2'
    remove_index :story_authors, :name => 'story_authors_created_at_index_1'
    remove_column :story_authors, :story_created_at
  end
end
