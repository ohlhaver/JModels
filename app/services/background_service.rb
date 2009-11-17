require 'benchmark'
#
#  BackgroundService is base class of the Background Algorithms
#
#  CandidateGeneration.new.run( :with_session => true ) do 
#    DuplicateMarker.new.run( :with_session => true )
#    GroupGeneration.new.run( :with_session => true )
#    ClusterGeneration.new.run( :with_session => true )
#    OpinionGeneration.new.run( :with_session => true )
#  end
#  repeat
#  
#  CandidateGeneration.new.run( :with_session => true, :start => { :time => t }) do
#    DuplicateMarker.new.run( :with_session => true )
#  end
#
class BackgroundService
  
  attr_reader :options
  
  def initialize( options = {})
    @options = options
  end
  
  def db
    @db ||= ActiveRecord::Base.connection
  end
  
  def logger
    @logger ||= ActiveRecord::Base.logger
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
    options[:with_benchmark] ? start_with_benchmark( options[:start] ) : start( options[:start] )
    begin
      yield if block_given?
    rescue StandardError => message
      logger.debug( message )
      logger.debug( message.backtrace.join("\n") )
    end
    if options[:with_benchmark] 
      finalize_with_benchmark( options[:finalize] )
    else
      finalize( options[:finalize] )
    end
    if options[:with_session]
      logger.info( "Background Service Benchmark: #{self.class.name}: Session: #{@session.id}\n" + Benchmark::Tms::CAPTION + (@start_bm + @finalize_bm).to_s )
      @session.update_attributes( :duration => self.duration )
      return 
    end
  end
  
  def start_with_benchmark( options = {} )
    @start_bm = Benchmark.measure{ start( options ) }
  end
  
  def finalize_with_benchmark( options = {})
    @finalize_bm = Benchmark.measure{ finalize( options ) }
  end
  
end