class BackgroundRunner
  
  attr_reader :name
  attr_reader :frequency
  attr_reader :last_run_at
  attr_reader :logger
  
  def initialize( name, logger, frequency = :once, last_run_at = nil, &block)
    @name = name
    @logger = logger
    @frequency = frequency
    @last_run_at = last_run_at
    @block = block
  end
  
  def run
    case (frequency) when :run_once 
      execute_once if last_run_at.nil?
    when :run_every_day
      execute_once if last_run_at.nil? || last_run_at < 24.hours.ago
    when :run_every_hour
      execute_once if last_run_at.nil? || last_run_at < 1.hour.ago
    else
      execute_once
    end
  end
  
  def execute_once
    logger.info("Running: #{name}")
    @block.call
    @last_run_at = Time.now.utc
  end
  
  def next_run_at
    case (frequency) when :run_once : nil
    when :run_every_day : last_run_at + 24.hours + 1
    when :run_every_hour : last_run_at + 1.hour + 1
    else Time.now.utc end
  end
  
end

class BackgroundRunnerPool
  
  attr_reader :logger
  
  def initialize( options = {} )
    ActiveRecord::Base.logger.level = 0
    @runners = Array.new
    @pause_between_iterations = options[:pause_between_iterations] || 5.seconds
    @pause_between_runners = options[:pause_between_runners] || 2.seconds
    @logger = Logger.new( options[:logfile] || "#{RAILS_ROOT}/log/#{name}.log", 5, 2_048_000 )
    @exit = false
  end
  
  def add_runner( name, frequency, &block )
    @runners.push( BackgroundRunner.new( name, logger, frequency, &block ) )
  end
  
  def name
    @name ||= self.class.name.underscore
  end
  
  def start
    logger.info "#{name.classify} Process Started"
    Signal.trap("INT"){ self.stop }
    Signal.trap("TERM"){ self.stop }
    Signal.trap("QUIT"){ self.stop }
    loop do
      @runners.each do | runner |
        break if exit?
        runner.run
        break if exit?
        sleep( @pause_between_runners.to_i ) if @pause_between_runners
      end
      break if exit?
      break unless sleep_until_work
    end
    @exit = false
    logger.info "#{name.classify} Process Exited"
  end
  
  protected
  
  def stop
    logger.info "#{name.classify} Process Terminating ..."
    @exit = true
  end
  
  def sleep_until_work
    current_time = Time.now.utc
    next_run_at = @runners.collect{ |x| x.next_run_at }.select{ |x| x }.sort.first
    return false unless next_run_at
    duration = ( next_run_at > current_time ? (next_run_at - Time.now.utc).to_i : 0 )
    duration = @pause_between_iterations.to_i if duration < @pause_between_iterations.to_i
    logger.debug "Sleeping for #{duration} secs."
    sleep( duration.to_i )
    return true
  end
  
  def exit?
    @exit == true
  end
  
end