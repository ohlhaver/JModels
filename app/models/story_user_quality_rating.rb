class StoryUserQualityRating < ActiveRecord::Base
  # database views on story_user_quality_ratings table with preference = 0
  class Ban < ActiveRecord::Base
    set_table_name :ban_user_quality_ratings
    set_primary_keys :story_id, :user_id

    belongs_to :story
    belongs_to :user
  end
  # database views on story_user_quality_ratings table with source = 0 && preference = 1
  class AuthorLow < ActiveRecord::Base
    set_table_name :author_low_user_quality_ratings
    set_primary_keys :story_id, :user_id

    belongs_to :story
    belongs_to :user
  end
  # database views on story_user_quality_ratings table with source = 0 && preference = 2
  class AuthorNormal < ActiveRecord::Base
    set_table_name :author_normal_user_quality_ratings
    set_primary_keys :story_id, :user_id

    belongs_to :story
    belongs_to :user
  end
  # database views on story_user_quality_ratings table with source = 0 && preference = 3
  class AuthorHigh < ActiveRecord::Base
    set_table_name :author_high_user_quality_ratings
    set_primary_keys :story_id, :user_id

    belongs_to :story
    belongs_to :user
  end
  # database views on story_user_quality_ratings table with source = 1 && preference = 1
  class SourceLow < ActiveRecord::Base
    set_table_name :source_low_user_quality_ratings
    set_primary_keys :story_id, :user_id

    belongs_to :story
    belongs_to :user
  end
  # database views on story_user_quality_ratings table with source = 1 && preference = 2
  class SourceNormal < ActiveRecord::Base
    set_table_name :source_normal_user_quality_ratings
    set_primary_keys :story_id, :user_id

    belongs_to :story
    belongs_to :user
  end
  # database views on story_user_quality_ratings table with source = 1 && preference = 3
  class SourceHigh < ActiveRecord::Base
    set_table_name :source_high_user_quality_ratings
    set_primary_keys :story_id, :user_id

    belongs_to :story
    belongs_to :user
  end
  
  set_primary_keys :story_id, :user_id
  
  belongs_to :story
  belongs_to :user
  
  validates_presence_of :story_id
  validates_presence_of :user_id
  
  class << self
    
    def hash_map( user, story_ids )
      hash_map = all( :select => 'story_id, quality_rating', :conditions => { :story_id => story_ids, :user_id => user.id } ).group_by{ |qr| qr.story_id }
      hash_map.each_pair{ |k,v| hash_map[k] = v.first.quality_rating }
      hash_map
    end
    
    unless method_defined?( :new_with_find )
      
      def new_with_find( attributes = {} )
        record = new_without_find( attributes )
        if record.valid? && ( duplicate_record = find( :first, :conditions => { :user_id => record.user_id, :story_id => record.story_id } ) )
          duplicate_record.attributes = attributes
          record = duplicate_record
        end
        return record
      end
      
      alias_method_chain :new, :find
      
    end
  end
end