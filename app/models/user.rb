class User < ActiveRecord::Base
  
  attr_accessor :login_field_required
  
  has_one :user_role
  has_one :preference, :as => :owner
  
  has_many :author_subscriptions, :as => :owner
  has_many :source_subscriptions, :as => :owner
  has_many :topic_subscriptions, :as => :owner
  has_many :story_subscriptions, :as => :owner
  has_many :multi_valued_preferences, :as => :owner
  
  before_create :set_user_role
  before_create :set_user_preference
  before_create :set_default_language
  
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
  
  def region_id
    preference.try( :region_id ) || Preference.default_region_id
  end
  
  def region_id=( r )
    set_user_preference
    rid =  ( Preference.select_value_by_name_and_code( :region_id, r.to_s.upcase ) || 
      Preference.select_value_by_name_and_id( :region_id, r.to_i ) ).try(:[], :id)
    if rid
      preference.region_id = rid
    end
  end
  
  def language_id
    preference.try( :default_language_id ) || Preference.default_language_id
  end
  
  def language_id=( l )
    set_user_preference
    lid =  ( Preference.select_value_by_name_and_code( :default_language_id, l ) || 
      Preference.select_value_by_name_and_id( :default_language_id, l ) ).try(:[], :id)
    return unless lid
    preference.default_language_id = lid
    preference.reset_search_lang_prefs!
    preference.search_language_ids = { lid => '1' }
    preference.interface_language_id = lid
  end
  
  def tag(region_id = self.region_id, langauge_id = self.language_id)
    "Region:#{region_id}:#{language_id}"
  end
  
  # If you are accessing the homepage cluster group for particular set of region and language
  def homepage_cluster_groups( region_id = self.region_id, language_id = self.language_id )
    clusters = create_default_homepage_cluster_groups
    clusters ||= ClusterGroup.homepage( self, :tag => tag( region_id, language_id ) )
  end
  
  def homepage_cluster_group_preferences
    create_default_homepage_cluster_groups
    multi_valued_preferences.preference( :homepage_clusters ).tag( tag ).all
  end
  
  protected
  
  def homepage_cluster_groups_exist?
    multi_valued_preferences.preference( :homepage_clusters ).tag( tag ).count > 0
  end
  
  def create_default_homepage_cluster_groups
    return nil if homepage_cluster_groups_exist?
    tag = "Region:#{region_id}:#{language_id}"
    clusters = ClusterGroup.homepage(:tag => tag ).all
    clusters.each{ |c|  MultiValuedPreference.preference( :homepage_clusters ).create( :owner => self, :value => c.id, :tag => tag ) }
  end
  
  def set_user_role
    self.user_role ||= UserRole.new
  end
  
  def set_user_preference
    self.preference ||= self.build_preference
  end
  
  def set_login_field_required
    self.login_field_required = self.third_party.blank?
    return true
  end
  
  def set_default_language
    return if self.preference.default_language_id
    self.language_id = Region::DefaultLanguage[ Preference.select_value_by_name_and_id( :region_id, self.region_id )[:code] ] || 'en'
  end
  
end