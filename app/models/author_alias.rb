class AuthorAlias < ActiveRecord::Base
  
  attr_accessor :skip_uniqueness_validation
  
  belongs_to :author
  before_validation :upcase_name
  
  validates_presence_of :name
  validates_uniqueness_of :name, :if => Proc.new{ |r| !r.skip_uniqueness_validation }
  validates_presence_of :author_id
  
  after_create :set_delta_index_flag
  after_destroy :set_delta_index_flag
  before_update :set_delta_index_flag, :if => Proc.new{ |r| r.name_changed? }
  
  def self.populate_missing
    transaction { 
      Author.find_each do |author|
        connection.execute( MasterDB::Insert::Ignore + " INTO author_aliases (author_id, name) VALUES ( #{author.id }, #{ connection.quote author.name.chars.upcase.to_s } )")
      end
    }
  end
  
  protected
  
  def set_delta_index_flag
    author.update_attributes( :delta => true ) if author
  end
  
  def upcase_name
    self.name = name.chars.upcase.to_s if name
  end
  
end