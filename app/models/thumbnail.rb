require 'fileutils'
require 'net/http'

class Thumbnail < ActiveRecord::Base
  
  belongs_to  :source
  has_one :story_thumbnail, :dependent => :destroy
  
  validates_presence_of  :content_type, :source_id, :height, :width, :download_url, :on => :create
  
  def full_storage_path
    RAILS_ROOT + "public/images/#{rand(0,10)}/#{URI.parse( download_url ).path}"
  end
  
  def image_path
    "/images/#{storage_url}"
  end
  
  def save_image( image_data )
    return unless self.story_thumbnail
    file = full_storage_path
    FileUtils.mkdir_p( File.dirname( file ) )
    File.open( file, 'w' ) do | file |
      file << image_data
    end
    self.storage_url = file.gsub( /.+images\//, '' )
    self.save( false )
  end
  
end
