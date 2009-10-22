class Source < ActiveRecord::Base
  has_many :source_regions, :dependent => :delete_all
  has_many :regions, :through => :source_regions, :source => :region
  
  has_many :feeds, :dependent => :destroy


  validates_presence_of    :id, :name, :url, :subscription_type
  validates_uniqueness_of  :id, :on => :create
  validates_inclusion_of   :subscription_type, :in => %w(public private paid)
end
