class SourceSubscription < ActiveRecord::Base
  
  serialize_with_options do
    dasherize false
    includes :source => Source.serialization_configuration(:short)
    except   :source_id, :owner_id, :owner_type, :category_id
  end
  
  belongs_to :owner, :polymorphic => true, :counter_cache => :source_count
  belongs_to :source
  
  validates_presence_of :source_id
  validates_uniqueness_of :category_id, :scope => [ :owner_type, :owner_id, :source_id ]
  
  #please update the vendor plugin, User has_many :source_subscriptions and User#max_pref_limit, User#cur_pref_count , User#out_of_limit? if you want to uncomment this
  #activate_user_account_restrictions :user => :owner, :association => :source_subscriptions
  
  after_save :destroy_record_if_blank
  after_create :turn_off_wizard
  
  protected
  
  def turn_off_wizard
    return unless owner.preference.wizard_on?( :source )
    owner.preference.wizards = { :source => '0' }
    owner.preference.save
  end
  
  def destroy_record_if_blank
    self.destroy if preference.nil?
  end
  
end