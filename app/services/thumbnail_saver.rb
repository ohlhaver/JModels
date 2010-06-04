gem 'taf2-curb'
require 'curb'

module Curb
  
  USER_AGENT = "jthumb http:://www.jurnalo.com"
  
  AUTH_TYPES = {
    :basic => 1,
    :digest => 2,
    :gssnegotiate => 4,
    :ntlm => 8,
    :digest_ie => 16
  }
      
  def self.open( url, options = {}, &block )
    retries = options.delete(:retries)
    retry_grace = options.delete(:retry_grace)
    return self.open_without_retries( url, options, &block ) unless retries
    response, message = nil, nil
    retries.times do
      begin
        response = open_without_retries( url, options.dup, &block)
      rescue Exception => message
      end
      break if response
      sleep( retry_grace ) if retry_grace
    end
    response.nil? ? raise( message ) : response 
  end
  
  def self.open_without_retries( url, options = {}, &block )
    catch_errors = options.delete(:catch_errors)
    html_only = options.delete( :html_only )
    easy = Curl::Easy.new(url) do |curl|
      curl.headers["User-Agent"] = (options[:user_agent] || USER_AGENT)
      curl.headers["If-Modified-Since"] = options[:if_modified_since].httpdate if options.has_key?(:if_modified_since)
      curl.headers["If-None-Match"] = options[:if_none_match] if options.has_key?(:if_none_match)
      curl.headers["Accept-encoding"] = 'gzip, deflate' if options.has_key?(:compress)
      curl.follow_location = true
      curl.userpwd = options[:http_authentication].join(':') if options.has_key?(:http_authentication)
      curl.http_auth_types = Array( options[:http_auth] ).collect{ |r| AUTH_TYPES[r] }.inject(0){|s,r| s = s | r } if options.has_key?( :http_auth )
      curl.max_redirects = options[:max_redirects] if options[:max_redirects]
      curl.timeout = options[:timeout] if options[:timeout]
      curl.connect_timeout = options[:connect_timeout] if options[:connect_timeout]
    end
    success, message = true, ''
    begin
      perform = true
      if html_only
        req = Curl::Easy.new(url) do |curl|
          curl.headers["User-Agent"] = (options[:user_agent] || USER_AGENT)
          curl.headers["If-Modified-Since"] = options[:if_modified_since].httpdate if options.has_key?(:if_modified_since)
          curl.headers["If-None-Match"] = options[:if_none_match] if options.has_key?(:if_none_match)
          curl.headers["Accept-encoding"] = 'gzip, deflate' if options.has_key?(:compress)
          curl.follow_location = true
          curl.userpwd = options[:http_authentication].join(':') if options.has_key?(:http_authentication)
          curl.http_auth_types = Array( options[:http_auth] ).collect{ |r| AUTH_TYPES[r] }.inject(0){|s,r| s = s | r } if options.has_key?( :http_auth )
          curl.max_redirects = options[:max_redirects] if options[:max_redirects]
          curl.timeout = options[:timeout] if options[:timeout]
          curl.connect_timeout = options[:connect_timeout] if options[:connect_timeout]
        end
        req.http_head
        perform = !req.content_type.match(/(html)|(xml)/).nil?
      end
      easy.perform if perform
    rescue Exception => message
      easy = false
      success = false
    end
    raise message unless success || catch_errors
    block.call( easy ) if block && easy
    return easy
  end
  
end


class ThumbnailSaver < BackgroundService
  
  def start( options = {} )
    # Saver
    Story.find_each( :conditions => [ '( thumb_saved IS ? OR thumb_saved = ? ) AND created_at > ?', nil, false, 1.week.ago ], :include => [ :thumbnail ] ) do |story|
      response = false 
      thumbnail = story.thumbnail
      if thumbnail && ( thumbnail.height == 80 || thumbnail.width == 80 ) && thumbnail.download_url
        logger.info( "Story #{story.id}: #{thumbnail.download_url}" )
        response = Curb.open( thumbnail.download_url, :timeout => 120, :catch_errors => true, :retries => 3 )
      end
      thumb_exists = ( response != false ) && ( response.response_code == 200 ) && thumbnail.save_image( response.body_str )
      story.set_thumb_saved_flag( thumb_exists ) do |s|
        s.image_path_cache = thumbnail.image_path
      end
      break if parent && parent.respond_to?( :exit? ) && parent.send( :exit? )
    end
    # Sweeper
    # while( true )
    #   sthumbs = StoryThumbnail.find( :all, :select => 'story_thumbnails.*',
    #     :joins => 'LEFT OUTER JOIN stories ON ( story_thumbnails.story_id = stories.id )',
    #     :conditions => 'stories.id IS NULL', :limit => 1000 )
    #   break if sthumbs.empty?
    #   StoryThumbnail.delete( sthumbs.collect( &:id ) )
    #   logger.info( 'StoryThumbnail Sweeped: ' + sthumbs.collect( &:id ).join(', ') )
    # end
    while( true )
      thumbnails = Thumbnail.find( :all, :select => 'thumbnails.*', 
        :joins => 'LEFT OUTER JOIN story_thumbnails ON (story_thumbnails.thumbnail_id = thumbnails.id)', 
        :conditions => [ 'story_thumbnails.story_id IS NULL' ], :limit => 1000 )
      break if thumbnails.empty?
      thumb_ids = Array.new
      thumbnails.each{ |thumb| thumb.remove_image; thumb_ids << thumb.id }
      Thumbnail.delete( thumb_ids )
      logger.info( 'Thumbnail Sweeped: ' + thumb_ids.join(', ') )
    end
  end
  
  def finalize( options = {} )
  end
  
end