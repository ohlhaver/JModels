class EmailAlert < BackgroundRunnerPool
  
  def initialize( options = {} )
    options.reverse_merge!( :pause_between_iterations => 5.minutes )
    super( options )
    if options[:test]
      add_runner( 'Test Email Alerts Processor', :run_once ) do
        EmailNotification.new( :logger => self.logger, :parent => self ).run( :with_session => true, :start => { :frequency => options[:frequency] } )
      end
    else
      add_runner( 'Invoice Alerts Processor', :run_every_day ) do
        EmailNotification.new( :logger => self.logger, :parent => self ).run( :with_session => true, :start => { :frequency => :invoice } )
      end
      add_runner( 'Weekly Email Alerts Processor', :run_every_day ) do
        EmailNotification.new( :logger => self.logger,  :parent => self ).run( :with_session => true, :start => { :frequency => :weekly } )
      end
      add_runner( 'Daily Email Alerts Processor', :run_every_two_hours ) do
        EmailNotification.new( :logger => self.logger,  :parent => self ).run( :with_session => true, :start => { :frequency => :daily } )
      end
      add_runner( 'Immediate Email Alerts Processor', :run_forever ) do
        EmailNotification.new( :logger => self.logger,  :parent => self ).run( :with_session => true, :start => { :frequency => :immediately } )
      end
    end
    
  end
  
end