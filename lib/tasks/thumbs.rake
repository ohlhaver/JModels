namespace :thumbs do
  
  desc "Start Jurnalo Thumbs Saver Process"
  task :start => :environment do
    fork do
      $0 = 'thumbs'
      Process.setsid
      Dir.chdir File.join( File.dirname(__FILE__), '..' )
      PidFile.store(  File.join( RAILS_ROOT, '/log/thumbs.pid' ), Process.pid )
      File.umask 0000
      STDIN.reopen "/dev/null"
      #STDOUT.reopen File.join( RAILS_ROOT, '/log/clustering.log' ), "a"
      STDOUT.reopen "/dev/null"
      STDERR.reopen STDOUT
      ActiveRecord::Base.connection.reconnect!
      EnqueuedEmail.connection.reconnect!
      BackgroundServiceDB.connection.reconnect! # Due to fork and MySQL Gone Away
      thumbs = Thumbs.new
      thumbs.start
    end
    puts "Thumbs Saver Service Started"
  end
  
  desc "Stop Jurnalo Thumbs Saver Process"
  task :stop => :environment do
    pid_file = File.join( RAILS_ROOT, '/log/thumbs.pid' )
    pid = PidFile.recall( pid_file )
    FileUtils.rm( pid_file ) rescue nil
    pid && Process.kill( "TERM", pid )
    sleep(10)
    puts "Thumbs Saver Service Stopped"
  end
  
  desc "Restart Jurnalo Thumbs Saver Process"
  task :restart => [ :stop, :start ] do
  end
  
  desc "Test Thumbs Saver Process"
  task :test => :environment do
    thumbs = Thumbs.new( :test => true, :logfile => STDOUT)
    thumbs.start
  end
  
end