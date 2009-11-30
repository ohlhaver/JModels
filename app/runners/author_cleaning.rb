class AuthorCleaning < BackgroundRunnerPool
  
  def initialize( options = {} )
    
    super( options )
    
    add_runner( 'Author Cleaning', :run_once ) do
      AuthorCleaner.new( :logger => self.logger ).run( :with_benchmark => true )
    end
    
  end
  
end