class AuthorCleaner < BackgroundService
  
  def start( options = {})
    @migrate_count = 0
    @split_author_count = 0
    total = Author.count
    progress = 0
    Author.find_each do |author|
      unless upcase_name?( author.name )
        author.name = author.name.chars.upcase.to_s
        original_author = Author.find( :first, :conditions => { :name => author.name } )
        migrate_author( author, original_author )
      end
      if author_names = multiple_authors?( author.name )
        authors = Author.create_or_find( author_names )
        split_author_into_many( author, authors )
      end
      progress += 1
      logger.info( "#{progress} / #{total} Authors Processed") if ( progress % 500 == 0 )
      break if parent && parent.send(:exit?)
    end
  end
  
  def finalize( options = {})
    logger.info( 'Migrate ' + @migrate_count.to_s + ' Authors.' )
    logger.info( 'Split ' + @split_author_count.to_s + ' Authors.' )
  end
  
  protected
  
  def migrate_author( source, target )
    Author.update_all("name = #{master_db.quote(source.name)}", { :id => source.id }) && return if target.nil? || target.id == source.id
    logger.info( "[#{source.name_was}:#{source.id}] => [#{target.name}:#{target.id}]")
    StoryAuthor.update_all( "author_id = '#{target.id}'", { :author_id => source.id } )
    Author.delete( source.id )
    @migrate_count += 1
  end
  
  def split_author_into_many( source, targets )
    logger.info("[#{source.name_was}:#{source.id}] =>")
    targets.each do |target|
      logger.info("\t#[#{target.name}:#{target.id}]")
    end
    target = targets.pop
    StoryAuthor.transaction do
      source.story_authors.each{ |sa|
        targets.each{ |t| master_db.execute("INSERT INTO story_authors( story_id, author_id ) VALUES( #{sa.story_id}, #{t.id} )") }
      }
      StoryAuthor.update_all( "author_id = '#{target.id}'", { :author_id => source.id } )
    end
    
    Author.delete( source.id )
    @split_author_count += 1
  end
  
  def multiple_authors?( text )
    new_text = JCore::Clean.author( text )
    text == new_text ? false : new_text
  end
  
  def upcase_name?( text )
    text.match(/[a-z]/).nil?
  end
  
end