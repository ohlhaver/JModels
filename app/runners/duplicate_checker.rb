class DuplicateChecker < BackgroundRunnerPool
  
  def initialize( options = {} )
    options.reverse_merge!( :pause_between_iterations => 1.seconds )
    super( options )
    if options[:test]
      add_runner( 'Duplicate Checker', :run_once ) do
        DuplicateDeletion.new( :logger => self.logger, :parent => self ).run( :with_session => true, :start => { :test => true } )
      end
    else
      add_runner( 'Duplicate Checker', :run_forever ) do
        DuplicateDeletion.new( :logger => self.logger, :parent => self ).run( :with_session => true )
      end
    end
    
  end
  
end