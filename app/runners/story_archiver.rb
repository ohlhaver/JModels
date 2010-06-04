require 'big_sitemap/builder'
require 'fileutils'
require 'nokogiri'

# Include Blocked Authors in Serialization Too
Story.class_eval do
  has_many  :story_authors
  has_many  :authors, :through => :story_authors, :source => :author
end

class StoryArchiver
  
  # SAX Reader for the Large XML Files.
  # Reads one story at a time.
  class Reader
    
    include Nokogiri
    
    class StoryBuilder < ::Builder::XmlMarkup
      
      def open_tag( name, attributes )
        attrs = attributes.inject([]){ |s,x| (s.last.nil? || s.last.size == 2) ? s.push([ x ]) : s.last.push(x); s }
        _start_tag( name, attrs.inject({}){ |s,x| s.merge!( x.first => x.last ) } )
      end
      
      def end_tag( name )
        _end_tag( name )
      end
    
    end
    
    
    class StoryHandler < XML::SAX::Document
      
      attr_reader :buffer

      def initialize( &block )
        @buffer = nil
        @block = block
      end
      
      def characters(string)
        self.buffer.text!( string ) if self.buffer
      end
      
      def start_element(name, attributes = [])
        if name == 'story'
          @target = ""
          @buffer = StoryBuilder.new(:target=>@target, :skip_instruct => true)
        end
        if self.buffer
          self.buffer.open_tag( name, attributes )
        end
      end
      
      def end_element( name )
        if self.buffer
          self.buffer.end_tag( name )
          if name == "story"
              @block.call( @target )
              @buffer = nil
          end
        end
      end
      
    end
    
    def initialize( filename )
      @filename = filename
    end
    
    def parser( &block )
      handler = StoryHandler.new( &block )
      XML::SAX::Parser.new( handler )
    end
    
    def each_story( &block )
      handler = StoryHandler.new( &block )
      parser = XML::SAX::Parser.new( handler )
      parser.parse_file( @filename )
    end
    
    def test( &block )
      require 'pp'
      count = 0
      each_story do |story|
        pp( block ? block.call(story) : story )
        count += 1
        break if count == 5
      end
    end
    
    def count
      count = 0
      each_story do |story|
        count += 1
      end
      return count
    end
    
  end
  
  # Writes directly to the file
  #
  class Builder < BigSitemap::Builder
    
    MAX_DOCS = 50000
    
    def initialize( options = {} )
      @max_docs = options.delete(:max_docs) || MAX_DOCS
      super( options )
    end
    
    def add_story( story )
      _rotate if @max_docs == @docs
      story.to_xml( :set => :archive, :builder => self, :skip_instruct => true, :root => 'story')
      @docs += 1
    end
    
    def _init_document
      @docs = 0
      instruct!
      _open_tag( 'stories', :max => @max_docs.to_s, :created_at => Time.now.utc.to_s(:db) )
    end
    
  end
  
  def initialize( options = {} )
    time = 1.month.ago
    @time = "#{time.year}-#{time.month}-01 00:00:00".to_time
    @options = options
    @options[:filename] ||= filename
    @mode = options.delete(:mode) || 'test'
    @options[:gzip] = true if self.mode == :production
    @options[:indent] ||= 2 unless @options[:gzip]
  end
  
  attr_accessor :mode
  
  def self.run( options = {} )
    options[:max_docs] ||= 100_000 # 100K approx size compressed size 80-120MB
    self.new( options ).run
  end
  
  def run
    files = []
    FileUtils.mkdir_p( File.dirname(filename) )
    archive = StoryArchiver::Builder.new( @options )
    begin
      archive_and_mark_for_delete( archive )
    ensure
      archive.close!
      files.concat archive.paths!
    end
    purge! if mode == :production
    files
  end
  
  def archive_and_mark_for_delete( archive )
    Story.update_all( 'delete_at = NULL' ) unless mode == :production
    story_ids_with_author = []
    story_ids_without_author = []
    delete_at = Time.now.utc - 1
    Story.find_each( :include => [ :authors, :story_metric, :story_content, :source, { :feed => :categories } ], :conditions => conditions ) do |story|
      archive.add_story( story )
      if story.authors.any?
        story_ids_with_author << story.id
      else
        story_ids_without_author << story.id
      end
      if story_ids_with_author.size > 999
        Story.update_all( { :delete_at => delete_at + 5.months }, { :id => story_ids_with_author } )
        story_ids_with_author.clear
      end
      if story_ids_without_author.size > 999
        Story.update_all( { :delete_at => delete_at }, { :id => story_ids_without_author } )
        story_ids_without_author.clear
      end
    end
    if story_ids_with_author.any?
      Story.update_all( { :delete_at => delete_at + 5.months }, { :id => story_ids_with_author } )
      story_ids_with_author.clear
    end
    if story_ids_without_author.any?
      Story.update_all( { :delete_at => delete_at }, { :id => story_ids_without_author } )
      story_ids_without_author.clear
    end
  end
  
  def purge!
    while( true )
      stories = Story.find( :all, :limit => 1000, :conditions => [ 'stories.delete_at < ?', Time.now.utc ] )
      break if stories.empty?
      stories.each{ |story| story.destroy }
    end
  end
  
  def filename
    "#{RAILS_ROOT}/db/archives/stories_#{@time.to_date.to_s(:db).gsub('-', '_')}"
  end
  
  def conditions
    [ 'stories.created_at < ? && stories.delete_at IS NULL', @time ]
  end
  
end