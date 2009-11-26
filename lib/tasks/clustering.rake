namespace :clustering do
  
  desc "Start Jurnalo Clustering Process"
  task :start => :environment do
    fork do
      $0 = 'clustering'
      Process.setsid
      Dir.chdir File.join( File.dirname(__FILE__), '..' )
      PidFile.store(  File.join( RAILS_ROOT, '/log/clustering.pid' ), Process.pid )
      File.umask 0000
      STDIN.reopen "/dev/null"
      #STDOUT.reopen File.join( RAILS_ROOT, '/log/clustering.log' ), "a"
      STDOUT.reopen "/dev/null"
      STDERR.reopen STDOUT
      clustering = Clustering.new
      clustering.start
    end
    puts "Clustering Service Started"
  end
  
  desc "Stop Jurnalo Clustering Process"
  task :stop => :environment do
    pid_file = File.join( RAILS_ROOT, '/log/clustering.pid' )
    pid = PidFile.recall( pid_file )
    FileUtils.rm( pid_file ) rescue nil
    pid && Process.kill( "TERM", pid )
    puts "Clustering Service Stopped"
  end
  
  desc "Restart Jurnalo Clustering Process"
  task :restart => [ :stop, :start ] do
  end
  
  desc "Test Clustering Algorithm: Run Once and Run in foreground"
  task :test => :environment do
    clustering = Clustering.new( :test => true, :logfile => STDOUT )
    clustering.start
    puts "Duplicates Count: #{Story.duplicates.count}"
    puts "Groups Count: #{StoryGroup.current_session.count}"
  end

end