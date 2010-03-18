class Source < ActiveRecord::Base
  
  named_scope :name_like, lambda{ |name| { :conditions => [ 'name LIKE ?', "#{name}%" ] } }
  
  serialize_with_options do
    dasherize false
    except :default_rating
  end
  
  serialize_with_options( :short ) do
    dasherize false
    only :id, :name
  end
  
  has_many :source_regions, :dependent => :delete_all
  has_many :regions, :through => :source_regions, :source => :region
  
  has_many :feeds, :dependent => :destroy
  
  validates_presence_of    :id, :name, :url, :subscription_type
  validates_uniqueness_of  :id, :on => :create
  validates_inclusion_of   :subscription_type, :in => %w(public private paid)
  
  has_many :source_subscriptions, :dependent => :destroy
  
end
