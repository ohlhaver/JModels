class QualityRating < BackgroundService
  
  def start( options = {} )
    
    # Calculating Default Author Ratings
    db.create_table( 'default_author_ratings_hotcopy', :force => true ) do |t|
      t.integer :rating
    end
    
    db.execute( 'INSERT OR IGNORE INTO default_author_ratings_hotcopy ( id ) 
      SELECT authors.id FROM authors')
      
    db.execute( 'UPDATE default_author_ratings_hotcopy
      SET rating = ( 
        SELECT CASE( COUNT( author_subscriptions.preference ) < 4 ) 
          WHEN 1 THEN NULL 
          ELSE AVG( author_subscriptions.preference ) END
        FROM author_subscriptions 
        WHERE author_subscriptions.author_id = default_author_ratings_hotcopy.id
            AND author_subscriptions.owner_type = "User" )')
        
    db.execute( 'DELETE FROM default_author_ratings_hotcopy WHERE rating IS NULL')
    
    # Doing Hot Swap
    db.transaction do 
      db.execute('DELETE FROM default_author_ratings 
        WHERE id NOT IN ( 
          SELECT default_author_ratings_hotcopy.id FROM default_author_ratings_hotcopy )')
      db.execute('INSERT OR IGNORE INTO default_author_ratings ( id ) 
        SELECT default_author_ratings_hotcopy.id FROM default_author_ratings_hotcopy')
      db.execute('UPDATE default_author_ratings 
        SET rating = ( SELECT default_author_ratings_hotcopy.id 
          FROM default_author_ratings_hotcopy 
          WHERE default_author_ratings_hotcopy.id = default_author_ratings.id )')
    end
    
    # Calculating Default Source Ratings
    db.create_table( 'default_source_ratings_hotcopy', :force => true ) do |t|
      t.integer :rating
    end
    
    db.execute( 'INSERT OR IGNORE INTO default_source_ratings_hotcopy ( id ) 
      SELECT source.id FROM sources')
    
    # TODO Change WHEN 1 to master_source_ratings 
    db.execute( 'UPDATE default_source_ratings_hotcopy
      SET rating = ( 
        SELECT CASE( COUNT( source_subscriptions.preference ) < 4 ) 
          WHEN 1 THEN 1
          ELSE AVG( source_subscriptions.preference ) END
        FROM source_subscriptions 
        WHERE source_subscriptions.source_id = default_source_ratings_hotcopy.id  AND 
          source_subscriptions.owner_type = "User")')
        
    db.execute( 'DELETE FROM default_source_ratings_hotcopy WHERE rating IS NULL')
    
    # Doing Hot Swap
    db.transaction do 
      db.execute('DELETE FROM default_source_ratings 
        WHERE id NOT IN ( 
          SELECT default_source_ratings_hotcopy.id FROM default_source_ratings_hotcopy )')
      db.execute('INSERT OR IGNORE INTO default_source_ratings ( id ) 
        SELECT default_source_ratings_hotcopy.id FROM default_source_ratings_hotcopy')
      db.execute('UPDATE default_source_ratings 
        SET rating = ( SELECT default_source_ratings_hotcopy.id 
          FROM default_source_ratings_hotcopy 
          WHERE default_source_ratings_hotcopy.id = default_source_ratings.id )')
    end
    
  end
  
  def finalize( options = {} )
    db.drop_table( 'default_author_ratings_hotcopy' )
    db.drop_table( 'default_source_ratings_hotcopy' )
  end
  
end