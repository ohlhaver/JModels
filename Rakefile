# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'tasks/rails'
require 'thinking_sphinx/tasks'
require 'fileutils'

module PidFile
  
  def self.store(file, pid)
    File.open(file, 'w') { |f| f << pid} 
  end
 
  def self.recall(file)
    IO.read(file).to_i rescue nil
  end
  
end

namespace :thinking_sphinx do
  
  task :index do
    ThinkingSphinx::Deltas::Job.cancel_thinking_sphinx_jobs
  end

  namespace :delayed_delta do
    
    desc "Start Delayed Delta Indexing"
    task :start => :app_env do
      fork do
        $0 = 'delayed_delta'
        Process.setsid
        Dir.chdir File.join( File.dirname(__FILE__), '..' )
        PidFile.store(  File.join( File.dirname(__FILE__), '/log/delayed_delta.pid' ), Process.pid )
        File.umask 0000
        STDIN.reopen "/dev/null"
        STDOUT.reopen File.join( File.dirname(__FILE__), '/log/delayed_delta.log' ), "a"
        STDERR.reopen STDOUT
        require 'delayed_job'
        ActiveRecord::Base.connection.reconnect!  
        BackgroundServiceDB.connection.reconnect! # Due to fork and MySQL Gone Away
        Delayed::Worker.new(
         :min_priority => ENV['MIN_PRIORITY'],
         :max_priority => ENV['MAX_PRIORITY']
        ).start
      end
      puts "Service Started"
    end
    
    desc "Stop Delayed Delta Indexing"
    task :stop do
      pid_file = File.join( File.dirname(__FILE__), '/log/delayed_delta.pid' )
      pid = PidFile.recall( pid_file )
      FileUtils.rm( pid_file ) rescue nil
      pid && Process.kill( "TERM", pid )
      puts "Service Stopped"
    end
    
    desc "Restart Delayed Delta Indexing"
    task :restart => [ :stop, :start ] do
    end
  end
end

namespace :ts do
  desc "Process stored delta index requests"
  task :dd do 
    task :start => "thinking_sphinx:delayed_delta:start"
    task :stop => "thinking_sphinx:delayed_delta:stop"
    task :restart => "thinking_sphinx:delayed_delta:restart"
  end
end


