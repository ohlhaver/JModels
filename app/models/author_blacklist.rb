class AuthorBlacklist < ActiveRecord::Base
  
  # Solution Assumes that the Black list is small
  # Therefore it iterates over the black
  def self.blacklist?( author )
    !find( :first, :conditions => [ '? REGEXP keyword', author.name ] ).nil?
  end
  
  # On new author creation
  def self.blacklist!( author )
    author.block!( :auto_blacklist ) if blacklist?( author )
  end
  
  # The blacklisted authors are stored in auto_blacklisted table
  # The blacklisted authors are created in one go
  def self.auto_block!
    connection.execute( "INSERT IGNORE INTO auto_blacklisted( author_id )
      SELECT authors.id 
      FROM `authors`, `author_blacklists` 
      WHERE (( authors.name REGEXP author_blacklists.keyword ) AND ( authors.block = 0 OR authors.auto_blacklisted = 1))" )
    Author.should_be_blacklisted.find_each do |author|
      author.block!( :auto_blacklist ) #auto_blocklist column is set to true
    end
  end
  
  # The blacklisted authors which are no more blacklisted according to list
  # gets removed from the auto_blacklisted in one go
  def self.auto_unblock!
    if self.count.zero?
      connection.execute( "DELETE FROM auto_blacklisted" )
    else
      connection.execute( "DELETE FROM auto_blacklisted WHERE author_id IN ( 
        SELECT authors.id 
        FROM `authors`, `author_blacklists` 
        WHERE (( authors.name NOT REGEXP author_blacklists.keyword ) AND authors.auto_blacklisted = 1)
      )" )
    end
    Author.should_not_be_blacklisted.find_each do |author|
      author.unblock! #auto_blacklist column is set to false
    end
  end
  
  def self.auto!
    auto_unblock!
    auto_block!
  end
  
end
