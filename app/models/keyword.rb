class Keyword < ActiveRecord::Base
  
  belongs_to :language
  
  validates_uniqueness_of :name, :scope => :language_id
  
  def self.calculate( story )
    JCore::Keyword.collection( story.title + ' ' + story.story_content.body, story.language.code )
  end
  
  def self.save( story )
    unless story.keyword_exists?
      keywords = calculate( story )
      transaction{ keywords.collect!{ |keyword| find_or_create( keyword, story.language_id ) } }
      transaction{
        keywords.each { |keyword| 
          KeywordSubscription.create( 
            :keyword_id => keyword.id, :story_id => story.id, 
            :frequency => keywords.rank( keyword.name ), 
            :excerpt_frequency => keywords.rank( keyword.name, :selected ) 
          )
        }
      }
      story.mark_keyword_exists
    end
  end
  
  def self.find_or_create( keyword, language_id )
    record = find(:first, :conditions => { :name => keyword, :language_id => language_id })
    record ||= create( :name => keyword, :language_id => language_id )
  end
  
end