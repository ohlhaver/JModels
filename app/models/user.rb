class User < ActiveRecord::Base
  
  attr_accessor :login_field_required
  
  has_one :user_role, :dependent => :delete
  has_one :paid_by_invoice, :dependent => :delete
  has_many :paid_by_paypals, :dependent => :delete_all
  has_one :preference, :as => :owner, :dependent => :delete
  
  has_many :author_subscriptions, :as => :owner, :conditions => { :block => false }, :extend => ActiveRecord::UserAccountRestriction::AssociationMethods
  has_many :source_subscriptions, :as => :owner, :extend => ActiveRecord::UserAccountRestriction::AssociationMethods
  has_many :topic_subscriptions, :as => :owner, :order => 'position ASC', :extend => ActiveRecord::UserAccountRestriction::AssociationMethods
  
  has_many :story_subscriptions, :as => :owner, :dependent => :delete_all
  has_many :multi_valued_preferences, :as => :owner, :dependent => :delete_all
  has_many :billing_records, :dependent => :delete_all
  has_many :account_status_points, :dependent => :delete_all # Time Point Record about Status
  
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
    #config.perishable_token_valid_for( 24.hours )
    config.disable_perishable_token_maintenance( true )
    config.session_class( 'UserSession'.constantize )
    
  end
  
  named_scope :with_preference, lambda { 
    { 
      :include  => :preference
    }
  }
  
  def plan_id
    @plan_id ||= account_status_points.find( :first, :conditions => [ 'starts_at < :time AND ends_at > :time', { :time => Time.now.utc } ] ).try( :plan_id )
  end
  
  def power_plan?
    plan_id == 1
  end
  
  def alert_monitor?
    false # This will be true for Business Users
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
  
  def default_locale
    Preference.select_value_by_name_and_id( :language_id, preference.try( :interface_language_id ) ).try( :[], :code ) || 'en'
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
  
  def tag(region_id = nil, language_id = nil)
    region_id ||= self.region_id
    language_id ||= self.language_id
    "Region:#{region_id}:#{language_id}"
  end
  
  # If you are accessing the homepage cluster group for particular set of region and language
  def homepage_cluster_groups( region_id = nil, language_id = nil )
    tag = self.tag( region_id, language_id )
    clusters = create_default_homepage_cluster_groups( tag )
    clusters ||= ClusterGroup.homepage( self, :tag => tag ).all( :order => 'position ASC' )
  end
  
  def homepage_cluster_group_preferences( *args )
    options = args.extract_options!
    region_id = options.delete( :region_id )
    language_id = options.delete( :language_id )
    tag = self.tag( region_id, language_id )
    logger.info(['-'*80, tag, '-'*80])
    args.push( options )
    create_default_homepage_cluster_groups( tag )
    multi_valued_preferences.preference( :homepage_clusters ).tag( tag ).all( *args )
  end
  
  def show_homepage_cluster_groups?
    MultiValuedPreference.owner( self ).preference( :homepage_boxes ).first( 
      :conditions => { :value => Preference.select_value_by_name_and_code( :homepage_boxes, :cluster_groups ).try( :[], :id ) } 
    ) != nil
  end
  
  def show_top_stories_cluster_group?
    MultiValuedPreference.owner( self ).preference( :homepage_boxes ).first(
      :conditions => { :value => Preference.select_value_by_name_and_code( :homepage_boxes, :top_stories_cluster_group ).try( :[], :id ) } 
    ) != nil
  end
  
  def self.import_old_user( user_attrs = {} )
    preference_attrs = user_attrs.delete( "preference" )
    topic_preferences = user_attrs.delete( "topic_subscriptions" )
    ( preference_attrs["search_language_ids"] || [] ).collect!{ |x| Preference.select_value_by_name_and_code( :language_id, x )[:id] }
    user = self.new( user_attrs )
    user.preference.attributes = preference_attrs
    user.terms_and_conditions_accepted = true
    user.login_field_required = false
    if user.save
      user.update_attribute( :active, true )
      user.account_status_points.create( :plan_id => 1, 
        :billing_record_id => 0, 
        :starts_at => Time.now.utc - 10, 
        :ends_at => Time.now.utc + 30.days 
      )
      user.instance_variable_set('@plan_id', 1) # for creating all the topic preferences
      topic_preferences.each do |topic_attrs|
        user.topic_subscriptions.create( topic_attrs )
      end
      user.account_status_points.delete_all
    end
    return user
  end
  
  def self.import_old_data( xml )
    users = Hash.from_xml( xml )["users"] rescue []
    count = 0
    users.each do |user_attrs|
      begin
        count += 1 unless import_old_user( user_attrs ).new_record?
      rescue StandardError
      end
    end
    return count
  end
  
  # It tries the heuristic approach to give either a 5 or 6 prefs to the users
  # who once where power users and have no. of prefs greater than the normal limit
  def max_pref_limit
    zeros, ones = 0, 0
    [ :topic_count, :source_count, :author_count ].each do |method|
      cnt = self.send( method )
      zeros += 1 if cnt == 0
      ones += 1 if cnt == 1
    end
    case ( zeros ) when 1 :
      ones == 1 ? 4 : 3
    when 2, 3:
      5
    when 0 :
      ones == 2 ? 3 : 2
    end
  end
  
  def cur_pref_count
    author_count + topic_count + source_count
  end
  
  def out_of_limit?
    !power_plan? && (cur_pref_count >= 5) ? true : false
  end
  
  protected
  
  def homepage_cluster_groups_exist?( tag = self.tag )
    multi_valued_preferences.preference( :homepage_clusters ).tag( tag ).count > 0
  end
  
  def create_default_homepage_cluster_groups( tag = self.tag )
    return nil if homepage_cluster_groups_exist?( tag )
    clusters = ClusterGroup.homepage( :tag => tag ).all( :order => 'position ASC' )
    clusters.each{ |c|  MultiValuedPreference.preference( :homepage_clusters ).create( :owner => self, :value => c.id, :tag => tag ) }
  end
  
  def set_user_role
    self.user_role ||= UserRole.new
  end
  
  def set_user_preference
    self.preference ||= self.build_preference
  end
  
  def set_login_field_required
    self.login_field_required = self.third_party.blank? if self.login_field_required.nil?
    return true
  end
  
  def set_default_language
    return if self.preference.default_language_id
    self.language_id = Region::DefaultLanguage[ Preference.select_value_by_name_and_id( :region_id, self.region_id ).try( :[], :code ) ] || 'en'
  end
  
end