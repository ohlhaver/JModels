class SourceSubscription < ActiveRecord::Base
  
  belongs_to :owner, :polymorphic => true
  belongs_to :source
  
  validates_presence_of :source_id
  validates_uniqueness_of :category_id, :scope => [ :owner_type, :owner_id, :source_id ]
  
  after_save :destroy_record_if_blank
  
  protected
  
  def destroy_record_if_blank
    self.destroy if preference.nil?
  end
  
end