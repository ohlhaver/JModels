class Region < ActiveRecord::Base
  validates_presence_of   :id, :name, :code
  validates_uniqueness_of :code
end
