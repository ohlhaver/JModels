class User < ActiveRecord::Base
  
  attr_accessor :login_field_required
  
  has_one :user_role
  has_one :preference, :as => :owner
  
  has_many :author_subscriptions, :as => :owner
  has_many :source_subscriptions, :as => :owner
  has_many :topic_subscriptions, :as => :owner
  has_many :story_subscriptions, :as => :owner
  
  before_create :set_user_role
  before_create :set_user_preference
  
  before_validation :set_login_field_required
  validates_presence_of :name
  validates_acceptance_of :terms_and_conditions_accepted, :allow_nil => false, :accept => true
  
  acts_as_authentic do |config|
    
    config.login_field( :login )
    config.validates_format_of_login_field_options( 
      :with => /\A[a-z][a-z0-9\.\+\-\_]+\z/, :message => I18n.t('error_messages.login_invalid', 
      :default => "small case letter followed by small case letters, numbers, and/or .-_+ please."),
      :if => Proc.new{ |x| x.login_field_required }
    )
    config.validates_length_of_login_field_options( :within => 3..40, :if => Proc.new{ |x| x.login_field_required } )
    config.merge_validates_uniqueness_of_login_field_options( :if => Proc.new{ |x| x.login_field_required }, :case_sensitive => true )
    
    config.crypted_password_field( :crypted_password )
    config.crypto_provider( Authlogic::CryptoProviders::Sha256 )
    config.ignore_blank_passwords
    config.merge_validates_confirmation_of_password_field_options( :if => Proc.new{ |x| x.login_field_required && x.send(:require_password?) } )
    config.merge_validates_length_of_password_confirmation_field_options( :if => Proc.new{ |x| x.login_field_required && x.send(:require_password?) } )
    config.merge_validates_length_of_password_field_options( :if => Proc.new{ |x| x.login_field_required && x.send(:require_password?) } )
    
    config.email_field( :email )
    config.validates_format_of_email_field_options
    config.validates_length_of_email_field_options( :within => 6..255 )
    config.validates_uniqueness_of_email_field_options
    config.logged_in_timeout( 30.minutes )
    config.perishable_token_valid_for( 24.hours )
    
    config.session_class( 'UserSession'.constantize )
    
  end
  
  def third_party?
    !third_party.blank?
  end
  
  protected
  
  def set_user_role
    self.user_role ||= UserRole.new
  end
  
  def set_user_preference
    self.preference ||= Preference.new
  end
  
  def set_login_field_required
    self.login_field_required = self.third_party.blank?
    return true
  end
  
end