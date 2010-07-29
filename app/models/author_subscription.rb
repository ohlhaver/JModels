class AuthorSubscription < ActiveRecord::Base
  
  serialize_with_options do
    dasherize false
    includes :author => Author.serialization_configuration(:short)
    except   :author_id, :owner_id, :owner_type
  end
  
  attr_accessor :created_or_updated
  
  belongs_to :owner, :polymorphic => true, :counter_cache => :author_count, :touch => true
  belongs_to :author
  
  validates_presence_of :author_id
  validates_uniqueness_of :author_id, :scope => [ :owner_type, :owner_id ]
  
  #before_create :set_author_preference
  #before_create :set_author_subscribed
  after_save :destroy_record_if_blank
  after_create :turn_off_wizard
  
  #please update the vendor plugin and User#max_pref_limit, User#cur_pref_count , User#out_of_limit? if you want to uncomment this
  #activate_user_account_restrictions :user => :owner, :association => :author_subscriptions
  
  named_scope :subscribed, lambda{ { :conditions => { :subscribed => true } } }
  
  named_scope :preferences, lambda{ { :conditions => 'author_subscriptions.preference IS NOT NULL' } }
  
  class << self
    
    unless method_defined?( :initialize_with_find_on_duplicate )
    
      def initialize_with_find_on_duplicate( attributes = {} )
        record = new_without_find_on_duplicate( attributes )
        if record.author_id && record.owner_id && record.owner_type && !record.valid?
          record = find( :first, :conditions => { :owner_type => record.owner_type, :owner_id => record.owner_id, :author_id => record.author_id } )
          record.attributes = attributes
        end
        return record
      end
    
      alias_method_chain :initialize, :find_on_duplicate
    
    end
  
  end
  
  protected
  
  def turn_off_wizard
    return unless owner.preference.wizard_on?( :author )
    owner.preference.wizards = { :author => '0' }
    owner.preference.save
  end
  
  def destroy_record_if_blank
    self.destroy if preference.nil? && !subscribed?
  end
  
  def set_author_preference
    self.preference = 3 if subscribed? && preference.nil?
    true
  end
  
  def set_author_subscribed
    self.subscribed = false if self.subscribed.nil? 
    self.subscribed = false if preference == 0 && subscribed?
    true
  end
  
end