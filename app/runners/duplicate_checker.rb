require 'benchmark'

class DuplicateChecker < BackgroundRunnerPool
  
  def initialize( options = {} )
    options.reverse_merge!( :pause_between_iterations => 1.seconds )
    super( options )
    
    if options[:test]
      add_runner( 'Duplicate Table Trimmer',  :run_once ) do
        bm = Benchmark.measure{  StoryTitle.purge! }
        self.logger.info( "Background Service Benchmark: Duplicate Table Trimmer:\n" + Benchmark::Tms::CAPTION + bm.to_s )
      end
      
      add_runner( 'Duplicate Checker', :run_once ) do
        DuplicateDeletion.new( :logger => self.logger, :parent => self ).run( :with_session => true, :start => { :test => true } )
      end
    else
      add_runner( 'Duplicate Table Trimmer',  :run_daily ) do
        bm = Benchmark.measure{  StoryTitle.purge! }
        self.logger.info( "Background Service Benchmark: Duplicate Table Trimmer:\n" + Benchmark::Tms::CAPTION + bm.to_s )
      end
      
      add_runner( 'Duplicate Checker', :run_forever ) do
        DuplicateDeletion.new( :logger => self.logger, :parent => self ).run( :with_session => true )
      end
    end
    
  end
  
end