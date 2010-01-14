namespace :email_alerts do
  
  desc "Start Jurnalo Email Alert Process"
  task :start => :environment do
    fork do
      $0 = 'email_alerts'
      Process.setsid
      Dir.chdir File.join( File.dirname(__FILE__), '..' )
      PidFile.store(  File.join( RAILS_ROOT, '/log/email_alert.pid' ), Process.pid )
      File.umask 0000
      STDIN.reopen "/dev/null"
      #STDOUT.reopen File.join( RAILS_ROOT, '/log/clustering.log' ), "a"
      STDOUT.reopen "/dev/null"
      STDERR.reopen STDOUT
      ActiveRecord::Base.connection.reconnect!  
      BackgroundServiceDB.connection.reconnect! # Due to fork and MySQL Gone Away
      EnqueuedEmail.connection.reconnect!
      email = EmailAlert.new
      email.start
    end
    puts "Email Alert Service Started"
  end
  
  desc "Stop Jurnalo Email Alert Process"
  task :stop => :environment do
    pid_file = File.join( RAILS_ROOT, '/log/email_alert.pid' )
    pid = PidFile.recall( pid_file )
    FileUtils.rm( pid_file ) rescue nil
    pid && Process.kill( "TERM", pid )
    sleep(10)
    puts "Email Alert Service Stopped"
  end
  
  desc "Restart Jurnalo Email Alert Process"
  task :restart => [ :stop, :start ] do
  end
  
  desc "Create Default Table to Store Emails on Email DB "
  task :migrate => :environment do
    email = EmailAlert.new( :test => true, :logfile => STDOUT, :frequency => :migrate )
    email.start
  end
  
  namespace :test do
    
    desc "Test Immediate Jurnalo Email Alert Process"
    task :immediately => :environment do
      email = EmailAlert.new( :test => true, :logfile => STDOUT, :frequency => :immediately )
      email.start
    end
  
    desc "Test Daily Jurnalo Email Alert Process"
    task :daily => :environment do
      email = EmailAlert.new( :test => true, :logfile => STDOUT, :frequency => :daily )
      email.start
    end
    
    desc "Test Weekly Jurnalo Email Alert Process"
    task :weekly => :environment do
      email = EmailAlert.new( :test => true, :logfile => STDOUT, :frequency => :weekly )
      email.start
    end
    
  end
  
end