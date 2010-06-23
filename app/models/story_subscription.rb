class StorySubscription < ActiveRecord::Base
  # O means articles to be read
  
  belongs_to :owner, :polymorphic => true, :touch => true
  
  validates_uniqueness_of :story_id, :scope => [ :owner_type, :owner_id ]
  before_create :set_preference
  after_create :turn_off_wizard
  
  belongs_to :story
  
  protected
  
  def turn_off_wizard
    return unless owner.preference.wizard_on?( :story )
    owner.preference.wizards = { :story => '0' }
    owner.preference.save
  end
  
  def set_preference
    self.preference = 0
  end
  
end