namespace :duplicate_checker do
  
  desc "Start Jurnalo Duplicate Checker"
  task :start => :environment do
    fork do
      $0 = 'duplicate_checker'
      Process.setsid
      Dir.chdir File.join( File.dirname(__FILE__), '..' )
      PidFile.store(  File.join( RAILS_ROOT, '/log/duplicate_checker.pid' ), Process.pid )
      File.umask 0000
      STDIN.reopen "/dev/null"
      #STDOUT.reopen File.join( RAILS_ROOT, '/log/clustering.log' ), "a"
      STDOUT.reopen "/dev/null"
      STDERR.reopen STDOUT
      ActiveRecord::Base.connection.reconnect!
      EnqueuedEmail.connection.reconnect!
      BackgroundServiceDB.connection.reconnect! # Due to fork and MySQL Gone Away
      duplicate_checker = DuplicateChecker.new
      duplicate_checker.start
    end
    puts "Duplicate Checker Service Started"
  end
  
  desc "Stop Jurnalo Duplicate Checkers"
  task :stop => :environment do
    pid_file = File.join( RAILS_ROOT, '/log/duplicate_checker.pid' )
    pid = PidFile.recall( pid_file )
    FileUtils.rm( pid_file ) rescue nil
    pid && Process.kill( "TERM", pid )
    sleep(10)
    puts "Duplicate Checker Service Stopped"
  end
  
  desc "Restart Jurnalo Duplicate Checker"
  task :restart => [ :stop, :start ] do
  end
  
  
  desc "Test Duplicate Checker"
  task :test => :environment do
    duplicate_checker = DuplicateChecker.new( :test => true, :logfile => STDOUT )
    duplicate_checker.start
  end
  
  desc "Bootstrap Duplicate Checker"
  task :bootstrap => :environment do
    duplicate_checker = DuplicateChecker.new( :bootstrap => true, :logfile => STDOUT )
    duplicate_checker.start
  end
  
end