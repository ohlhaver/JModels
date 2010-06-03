require 'big_sitemap'
require 'net/scp'

Source.class_eval do
  
  def to_param
    "#{id}-#{name.to_ascii_s.downcase.gsub(/\.|\ /, '-')}"
  end
  
end

Author.class_eval do
  
  def to_param
    "#{id}-#{name.to_ascii_s.downcase.gsub(/\.|\ /, '-')}"
  end
  
end

class Sitemap < BigSitemap
  
  def polymorphic_url( record )
    case ( record ) when StoryGroup then
      URI.encode( if story_group_key == 0 then
        "#{root_url}/stories?q=#{record.top_keywords.join('+AND+')}&edition=#{record.language.default_edition}"
      else
        keyword = record.top_keywords[ story_group_key - 1 ]
        "#{root_url}/stories?q=#{keyword}&edition=#{record.language.default_edition}"
      end )
    else nil end
  end
  
  def self.run( mode = :production )
    sitemap = new( 
      :url_options => {:host => 'www.jurnalo.com'}, 
      :ping_yahoo => true, 
      :ping_google => true, 
      :ping_bing => true, 
      :ping_ask => true, 
      :yahoo_app_id => "k4tdVwbV34F2_XYD6iuQxVckLwHKjj2hqXOUctAJdeP7s0kxV42OHbNGYmKsa9FvYtLr69A-",
      :gzip => ( mode == :production ? true : false )
    )
    Author.find_in_batches do |batch|
      author_ids = batch.collect( &:id )
      story_authors = StoryAuthor.find(:all, :select => '*, COUNT(*) AS story_count', :conditions => { :author_id => author_ids}, :group => 'author_id')
      valid_author_ids = story_authors.select{ |sa| sa.send(:read_attribute, 'story_count').to_i > 1 }.collect( &:author_id )
      Author.update_all( 'sitemap=1', { :id => valid_author_ids })
    end
    sitemap.add( Author, {
        :conditions       => { :block => false, :sitemap => true },
        :path             => 'authors',
        :change_frequency => 'daily',
        :priority         => 0.75
    })
    sitemap.add( Source, {
       :path             => 'sources',
       :change_frequency => 'daily',
       :priority         => 0.5
    })
    sitemap.add( StoryGroup, {
      :include          => :language,
      :path             => 'stories',
      :change_frequency => 'daily',
      :priority         => 0.6
    })
    sitemap.add( StoryGroup, {
      :include          => :language,
      :conditions       => [ 'story_count > ?',  4 ],
      :path             => 'stories',
      :change_frequency => 'daily',
      :priority         => 0.5
    })
    sitemap.add( StoryGroup, {
      :include          => :language,
      :conditions       => [ 'story_count > ?',  4 ],
      :path             => 'stories',
      :change_frequency => 'daily',
      :priority         => 0.45
    })
    sitemap.add( StoryGroup, {
      :include          => :language,
      :conditions       => [ 'story_count > ?',  4 ],
      :path             => 'stories',
      :change_frequency => 'daily',
      :priority         => 0.40
    })
    sitemap.generate
    if mode == :production
      sitemap.transfer_files
      sitemap.ping_search_engines
    end
  end
  
  def transfer_files
    host = "10.176.252.159"
    user = "jurnalo"
    pass = "rosenwel"
    remote_files = []
    Net::SCP.start(host, user, :passphrase => pass) do |scp|
      @sitemap_files.each do |file|
        remote_file = "/home/jurnalo/apps/JWebApp/shared/sitemaps/#{File.basename(file)}"
        scp.upload! file, (remote_file + ".duplicate")
        remote_files.push( remote_file )
      end
    end
    Net::SSH.start(host, user, :passphrase => pass) do |ssh|
      remote_files.each do |remote_file|
        ssh.exec!( "mv -f #{remote_file}.duplicate #{remote_file}")
      end
    end
    remote_files.clear
  end
  
  private
  
  def story_group_names
    @story_group_names ||= [ 'stories', 'k1_stories', 'k2_stories', 'k3_stories' ].reverse
  end
  
  def story_group_keys
    @story_group_keys ||= [ 0, 1, 2, 3 ].reverse
  end
  
  def story_group_key
    @story_group_key
  end

  def with_sitemap(name, options={})
    options[:index] = name == 'index'
    if name == "story_groups"
      name = story_group_names.pop
      @story_group_key = story_group_keys.pop
    end
    options[:filename] = "#{@file_path}/sitemap_#{name}"
    options[:max_urls] = @options[:max_per_sitemap]

    unless options[:gzip] = @options[:gzip]
      options[:indent] = 2
    end

    sitemap = Builder.new(options)

    begin
      yield sitemap
    ensure
      sitemap.close!
      @sitemap_files.concat sitemap.paths!
    end
  end
  
end
