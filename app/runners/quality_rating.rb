class QualityRating < BackgroundRunnerPool
  
  def initialize( options = {} )
    options.reverse_merge!( :pause_between_iterations => 5.seconds )
    super( options )
    
    if options[:test]
      
      if options[:inc]
        
        add_runner( 'Quality Ratings Incremental', :run_once ) do
          QualityRatingGeneration.new( :logger => self.logger, :parent => self ).run( :with_session => true, :start => { :incremental => true } )
        end
        
      else
        
        add_runner( 'Quality Ratings Overall', :run_once ) do
          QualityRatingGeneration.new( :logger => self.logger, :parent => self ).run( :with_session => true )
        end
        
      end
    
    else
      
      # add_runner( 'Quality Ratings Overall', :run_every_day ) do
      #   QualityRatingGeneration.new( :logger => self.logger,  :parent => self ).run( :with_session => true )
      # end
      
      add_runner( 'Quality Ratings Incremental', :run_forever ) do
        QualityRatingGeneration.new( :logger => self.logger,  :parent => self ).run( :with_session => true, :start => { :incremental => true } )
      end
      
    end
    
  end
  
end