class Developer < ActiveRecord::Base
  has_many :application_developers
  has_many :applications, :through => :application_developers, :source => :application
end
