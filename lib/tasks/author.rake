namespace :authors do
  
  namespace :cleaning do
    
    desc "Clean authors database in foreground"
    task :run => :environment do
      cleaning = AuthorCleaning.new( :logfile => STDOUT )
      cleaning.start
    end
  
    desc "Clean authors database in background"
    task :start => :environment do
      fork do
        $0 = 'author_cleaning'
        Process.setsid
        Dir.chdir File.join( File.dirname(__FILE__), '..' )
        PidFile.store(  File.join( RAILS_ROOT, '/log/clustering.pid' ), Process.pid )
        File.umask 0000
        STDIN.reopen "/dev/null"
        STDOUT.reopen "/dev/null"
        STDERR.reopen STDOUT
        ActiveRecord::Base.connection.reconnect!
        BackgroundServiceDB.connection.reconnect!
        cleaning = AuthorCleaning.new
        clean
      end
      puts "Author Cleaning Started in Background"
    end
    
  end
  
end