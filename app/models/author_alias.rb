class AuthorAlias < ActiveRecord::Base
  
  attr_accessor :skip_uniqueness_validation
  
  belongs_to :author
  before_save :upcase_name
  
  validates_presence_of :name
  validates_uniqueness_of :name, :if => Proc.new{ |r| !r.skip_uniqueness_validation }
  
  def self.populate_missing
    transaction { 
      Author.find_each do |author|
        connection.execute( MasterDB::Insert::Ignore + " INTO author_aliases (author_id, name) VALUES ( #{author.id }, #{ connection.quote author.name.chars.upcase.to_s } )")
      end
    }
  end
  
  protected
  
  def upcase_name
    self.name = name.chars.upcase.to_s
  end
  
end