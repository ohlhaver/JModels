class StorySubscription < ActiveRecord::Base
  # O means articles to be read
  
  belongs_to :owner, :polymorphic => true
  
  validates_uniqueness_of :story_id, :scope => [ :owner_type, :owner_id ]
  before_create :set_preference
  belongs_to :story
  
  protected
  
  def set_preference
    self.preference = 0
  end
  
end