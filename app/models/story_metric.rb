class StoryMetric < ActiveRecord::Base
  
  belongs_to :story
  
  serialize_with_options( :short ) do
    dasherize false
    only :master_id
  end
  
  before_save :set_delta_index_story
  after_save :set_story_delta_flag, :update_story_group_memberships
  after_destroy :set_story_delta_flag
  
  def self.create_or_update( attributes )
    metric = StoryMetric.find(:first, :conditions => { :story_id => attributes[:story_id] }) || StoryMetric.new
    metric.attributes = attributes
    metric.save ? metric : nil
  end
  
  def set_delta_index_story
    @delta_index_story = master_id_changed?
    return true
  end
  
  def update_story_group_memberships
    StoryGroupMembership.update_all( 'master_id = ' + connection.quote( self.master_id ) , { :story_id => self.story_id } )
  end
  
  def set_story_delta_flag
    story.update_attribute( :delta, true ) if frozen? || @delta_index_story
  end
  
end