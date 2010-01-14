namespace :quality_rating do
  
  desc "Start Jurnalo Quality Rating Process"
  task :start => :environment do
    fork do
      $0 = 'quality_rating'
      Process.setsid
      Dir.chdir File.join( File.dirname(__FILE__), '..' )
      PidFile.store(  File.join( RAILS_ROOT, '/log/quality_rating.pid' ), Process.pid )
      File.umask 0000
      STDIN.reopen "/dev/null"
      #STDOUT.reopen File.join( RAILS_ROOT, '/log/clustering.log' ), "a"
      STDOUT.reopen "/dev/null"
      STDERR.reopen STDOUT
      ActiveRecord::Base.connection.reconnect!
      EnqueuedEmail.connection.reconnect!
      BackgroundServiceDB.connection.reconnect! # Due to fork and MySQL Gone Away
      quality_rating = QualityRating.new
      quality_rating.start
    end
    puts "Quality Rating Service Started"
  end
  
  desc "Stop Jurnalo Quality Rating Process"
  task :stop => :environment do
    pid_file = File.join( RAILS_ROOT, '/log/quality_rating.pid' )
    pid = PidFile.recall( pid_file )
    FileUtils.rm( pid_file ) rescue nil
    pid && Process.kill( "TERM", pid )
    sleep(10)
    puts "Quality Rating Service Stopped"
  end
  
  desc "Restart Jurnalo Clustering Process"
  task :restart => [ :stop, :start ] do
  end
  
  
  desc "Test Overall Quality Rating Algorithm"
  task :test => :environment do
    quality_rating = QualityRating.new( :test => true, :logfile => STDOUT )
    quality_rating.start
  end
  
  desc "Test Incremental Quality Rating Algorithm"
  task :test_inc => :environment do
    quality_rating = QualityRating.new( :test => true, :inc => true, :logfile => STDOUT)
    quality_rating.start
  end
  
end