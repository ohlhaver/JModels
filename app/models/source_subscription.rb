class SourceSubscription < ActiveRecord::Base
  
  serialize_with_options do
    dasherize false
    includes :source => Source.serialization_configuration(:short)
    except   :source_id, :owner_id, :owner_type, :category_id
  end
  
  belongs_to :owner, :polymorphic => true
  belongs_to :source
  
  validates_presence_of :source_id
  validates_uniqueness_of :category_id, :scope => [ :owner_type, :owner_id, :source_id ]
  
  activate_user_account_restrictions :user => :owner, :association => :source_subscriptions
  
  after_save :destroy_record_if_blank
  
  protected
  
  def destroy_record_if_blank
    self.destroy if preference.nil?
  end
  
end