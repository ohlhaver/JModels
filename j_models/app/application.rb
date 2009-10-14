class Application < ActiveRecord::Base
  has_many :application_developers
  has_many :developers, :through => :application_developers, :source => :developer

end
