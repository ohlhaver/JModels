class Source < ActiveRecord::Base
  
  named_scope :name_like, lambda{ |name| { :conditions => [ 'name LIKE ?', "#{name}%" ] } }
  
  serialize_with_options do
    dasherize false
    except :default_rating
  end
  
  serialize_with_options( :user_preference ) do
    dasherize false
    except :default_rating
    map_include :average_user_preference => :average_user_preference_serialize, :user_preference_count => :user_preference_count_serialize 
  end
  
  serialize_with_options( :short ) do
    dasherize false
    only :id, :name
  end
  
  attr_accessor :average_user_preference
  attr_accessor :user_preference_count
  
  has_many :source_regions, :dependent => :delete_all
  has_many :regions, :through => :source_regions, :source => :region
  
  has_many :feeds, :dependent => :destroy
  
  validates_presence_of    :id, :name, :url, :subscription_type
  validates_uniqueness_of  :id, :on => :create
  validates_inclusion_of   :subscription_type, :in => %w(public private paid)
  
  has_many :source_subscriptions, :dependent => :destroy
  
  def set_user_preference_metrics
    subscription = SourceSubscription.first( :select => 'SUM( preference ) as user_preference_sum, COUNT( preference ) as user_preference_count',
      :conditions => { :source_id => self.id }, :group => 'source_id' )
    sum = self.default_preference || 1
    count = 1
    if subscription
      sum += subscription.send( :read_attribute, 'user_preference_sum' ).to_i
      count += subscription.send( :read_attribute, 'user_preference_count' ).to_i
    end
    self.average_user_preference = sum.to_f / count
    self.user_preference_count = count
  end
  
  protected
  
  def average_user_preference_serialize( options = {} )
    self.average_user_preference.to_xml( :root => options[:root], :builder => options[:builder], :skip_instruct=>true )
  end
  
  def user_preference_count_serialize( options = {} )
    self.user_preference_count.to_xml( :root => options[:root], :builder => options[:builder], :skip_instruct=>true )
  end
  
end
