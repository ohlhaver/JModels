require 'fileutils'
require 'uri'

class Thumbnail < ActiveRecord::Base
  
  belongs_to  :source
  has_one :story_thumbnail, :dependent => :destroy
  
  validates_presence_of  :content_type, :source_id, :height, :width, :download_url, :on => :create
  
  def random_storage_path
    RAILS_ROOT + "/public/images/#{rand(10)}" + URI.parse( self.download_url ).path.to_s.gsub('/images/', '/')
  end
  
  def image_path
    "/images/#{storage_url}"
  end
  
  def save_image( image_data )
    file = random_storage_path
    FileUtils.mkdir_p( File.dirname( file ) )
    File.open( file, 'w' ) do | f |
      f << image_data
    end
    self.storage_url = file.gsub( /.+images\//, '' )
    self.save( false )
  end
  
end
