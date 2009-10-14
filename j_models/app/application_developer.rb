class ApplicationDeveloper < ActiveRecord::Base
  belongs_to :application
  belongs_to :developer
end
