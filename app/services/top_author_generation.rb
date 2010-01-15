
class TopAuthorGeneration < BackgroundService
  
  def start( options = {} )
    
    master_db.execute( 'DELETE FROM bg_top_authors WHERE active = ' + master_db.quoted_false )
    Author.with_subscription_count.find_each do | author |
      return if exit?
      master_db.execute( 'INSERT INTO bg_top_authors( author_id, subscription_count ) VALUES (' + master_db.quote_and_merge( author.id, author.subscription_count ) + ')')
    end
    master_db.execute( 'DELETE FROM bg_top_authors WHERE active = ' + master_db.quoted_true )
    master_db.execute( 'UPDATE bg_top_authors SET active = ' + master_db.quoted_true )
    
    master_db.execute( 'DELETE FROM bg_top_author_stories WHERE active = ' + master_db.quoted_false )
    Story.since( 24.hours.ago ).with_author_subscription_count.find_each do | story |
      return if exit?
      Story.insert_into_top_author_stories( story.id, story.author_subscription_count )
    end
    master_db.execute( 'DELETE FROM bg_top_author_stories WHERE active = ' + master_db.quoted_true )
    master_db.execute( 'UPDATE bg_top_author_stories SET active = ' + master_db.quoted_true )
    
  end
  
  def finalize( options = {} )
    
  end
  
end