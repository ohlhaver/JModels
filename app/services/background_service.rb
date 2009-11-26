require 'benchmark'
#
#  BackgroundService is base class of the Background Algorithms
#  Every Day Run: BackgroundMigration.new.run( :with_session => true )
#  
#  CandidateGeneration.new.run( :with_session => true ) do 
#    DuplicateMarker.new.run( :with_session => true )
#    GroupGeneration.new.run( :with_session => true )
#    OpinionGeneration.new.run( :with_session => true )
#  end
#  repeat
#  
#  CandidateGeneration.new.run( :with_session => true, :start => { :time => t }) do
#    DuplicateMarker.new.run( :with_session => true )
#  end
#
$background_database_config = YAML.load_file( File.join( RAILS_ROOT, '/config/background.yml' ) )

class BackgroundServiceDB < ActiveRecord::Base
  self.establish_connection( $background_database_config[ RAILS_ENV ] ) 
end

class BackgroundService
  
  attr_reader :options
  
  def initialize( options = {})
    @options = options
    @master_db = ActiveRecord::Base.connection # Defaults Rails Connection
    @cluster_db = BackgroundServiceDB.connection
    @logger = options[:logger] || ActiveRecord::Base.logger
    @start_bm    = Benchmark.measure{}
    @run_bm      = Benchmark.measure{}
    @finalize_bm = Benchmark.measure{}
  end
  
  def master_db
    @master_db.reconnect!
    @master_db
  end
  
  def cluster_db
    @cluster_db.reconnect!
    @cluster_db
  end
  
  alias_method :db, :cluster_db
  
  def logger
    @logger
  end
  
  def duration( scope = :start_and_finalize )
    case( scope ) when :all :  ( @start_bm + @run_bm + @finalize_bm ).real
    when :start_and_finalize : @start_bm.real + @finalize_bm.real
    when :start : @start_bm.real
    when :finalize : @finalize_bm.real
    end
  end
  
  def job_id
    @job_id ||= "BjSession::Jobs::#{self.class.name}".constantize
  end
  
  def run( options = {} )
    if options[:with_session]
      @session = BjSession.create( :job_id => self.job_id )
      options[:with_benchmark] = true
    end
    begin
      options[:with_benchmark] ? start_with_benchmark( options[:start] || {} ) : start( options[:start] || {})
      yield if block_given?
      options[:with_benchmark] ? finalize_with_benchmark( options[:finalize] || {}) : finalize( options[:finalize] || {})
    rescue StandardError => message
      logger.info( message )
      logger.debug( message.backtrace.join("\n") )
    end
    @session.update_attributes( :duration => self.duration, :running => false ) if options[:with_session]
    if options[:with_benchmark]
      logger.info( "Background Service Benchmark: #{self.class.name}: Session: #{@session.id}\n" + Benchmark::Tms::CAPTION + (@start_bm + @finalize_bm).to_s )
    end
  end
  
  def start_with_benchmark( options = {} )
    @start_bm = Benchmark.measure{ start( options ) }
  end
  
  def finalize_with_benchmark( options = {})
    @finalize_bm = Benchmark.measure{ finalize( options ) }
  end
  
end