# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
if defined?( Rails ) && Rails.initialized?
  
  ActiveRecord::Base.connection # Connect to database using former RAILS_ROOT
  
  RAILS_ROOT_ORIGINAL = RAILS_ROOT 
  Object.send( :remove_const, :RAILS_ROOT )
  RAILS_ROOT = File.expand_path( File.dirname(__FILE__) + '/..' )
  ActiveSupport::Dependencies.load_paths.insert( 0, RAILS_ROOT + '/app/models' )
  
  gem( 'thinking-sphinx-099', :lib => 'thinking_sphinx', :version => '1.3.2' )
  require 'thinking_sphinx'
  gem( 'ts-delayed-delta', :lib => 'thinking_sphinx/deltas/delayed_delta', :version => '1.0.0' )
  require 'thinking_sphinx/deltas/delayed_delta'
  gem( 'jcore', :lib => 'jcore', :version => '>=1.0.5' )
  require 'jcore'
  gem( 'algorithms', :lib => 'algorithms', :version => '=0.3.0')
  require 'algorithms'
  
  Dir[ File.join( RAILS_ROOT ,'app/models/*.rb' ) ].each do |model_file|
    load model_file
  end
  
  Object.send( :remove_const, :RAILS_ROOT )
  RAILS_ROOT = RAILS_ROOT_ORIGINAL
  Object.send( :remove_const, :RAILS_ROOT_ORIGINAL )
  ActiveSupport::Dependencies.load_paths.shift
  
else
  
  require File.join(File.dirname(__FILE__), 'boot')
  
  Rails::Initializer.run do |config|
    config.gem( 'thinking-sphinx-099', :lib => 'thinking_sphinx', :version => '1.3.2' )
    config.gem( 'ts-delayed-delta', :lib => 'thinking_sphinx/deltas/delayed_delta', :version => '1.0.0' )
    config.gem( 'jcore', :version =>'>=1.0.5', :lib => 'jcore' )
    config.gem( 'algorithms', :version => '=0.3.0', :lib => 'algorithms' )
    config.frameworks -= [ :active_resource, :action_mailer, :action_controller,  :action_view ]
    config.routes_configuration_file = nil
    config.time_zone = 'UTC'
  end

end
ActiveSupport::Dependencies.load_paths.insert( 0, RAILS_ROOT + '/app/services' )