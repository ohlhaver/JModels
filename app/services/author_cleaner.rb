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
    end
  end
  
  def finalize( options = {})
    logger.info( 'Migrate ' + @migrate_count.to_s + ' Authors.' )
    logger.info( 'Split ' + @split_author_count.to_s + ' Authors.' )
  end
  
  protected
  
  def migrate_author( source, target )
    source.save && return if target.nil? || target.id == source.id
    logger.info( "[#{source.name_was}:#{source.id}] => [#{target.name}:#{target.id}]")
    StoryAuthor.transaction do
      source.story_authors.each{ |sa| sa.update_attributes( :author_id => target.id ) }
    end
    source.destroy
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
        sa.update_attributes( :author_id => target.id )
        targets.each{ |t| StoryAuthor.create( :story_id => sa.story_id, :author_id => t.id ) }
      }
    end
    source.destroy
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