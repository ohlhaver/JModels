class Thumbs < BackgroundRunnerPool
  
  def initialize( options = {} )
    options.reverse_merge!( :pause_between_iterations => 1.minute )
    super( options )
    if options[:test]
      add_runner( 'Thumbnail Saver', :run_once ) do
        ThumbnailSaver.new( :logger => self.logger,  :parent => self ).run( :with_session => true, :start => { :incremental => true } )
      end
    else
      add_runner( 'Thumbnail Saver', :run_forever ) do
        ThumbnailSaver.new( :logger => self.logger,  :parent => self ).run( :with_session => true, :start => { :incremental => true } )
      end
    end
  end
  
end