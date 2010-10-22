module DelayedWorkerPatch
  attr_accessor :last_block_return_value
  def start_with_block( &block )
    say "*** Starting job worker #{Delayed::Job.worker_name}"
    trap('TERM') { say 'Exiting...'; $exit = true }
    trap('INT')  { say 'Exiting...'; $exit = true }
    loop do
      count = 0
      unless $test
        result = nil
        realtime = Benchmark.realtime do
          result = Delayed::Job.work_off
        end
        count = result.sum
      end
      say( "#{count} jobs processed at %.4f j/s, %d failed ..." % [count / realtime, result.last] ) if count > 0
      self.last_block_return_value = block.call( self.last_block_return_value ) if block
      break if $exit
      sleep(Delayed::Worker::SLEEP)
    end
  ensure
    Delayed::Job.clear_locks!
  end
end

UpdateSearchdIndices = Proc.new{ |sync_main_index_flag|
  puts "Syncing New Indices ..."
  dir = ThinkingSphinx::Configuration.instance.searchd_file_path
  glob_suffix =  "/*.new.*"
  remote_servers = YAML.load( File.read( Rails.root.to_s + "/config/searchd_servers.yml" ) )[ Rails.env ]
  new_indices = false
  Dir[ dir + glob_suffix ].each do |source_file|
    dest_file = source_file
    new_indices = true
    remote_servers.each{ |server| sh "scp #{source_file} #{server}:#{dest_file}" }
    sh "mv -f #{source_file} #{source_file.gsub( '.new.', '.' )}"
    puts "Synced #{source_file}"
  end
  if new_indices
    pid_file = ThinkingSphinx::Configuration.instance.pid_file
    remote_servers.each{ |server| 
      sh "ssh #{server} 'kill -s SIGHUP `cat #{pid_file}`'"
    }
    puts "Syncing Complete"
  else
    puts "No new index to sync"
  end
  
}

MainIndexRunner = Proc.new{ |hash_value|
  unless $exit
    hash_value ||= Hash.new
    last_value = hash_value[ :full_index_at ]
    sync_main_index_flag = hash_value[ :sync_main_index_flag ] || false
    if ( last_value.nil? && Time.now.utc.hour == 2 ) || ( last_value && last_value < 24.hours.ago )
      hash_value[ :full_index_at ] = Time.now.utc
      sync_main_index_flag = hash_value[ :sync_main_index_flag ] = true
      Rake::Task['thinking_sphinx:index'].invoke
      dir = ThinkingSphinx::Configuration.instance.searchd_file_path
      # new index fix. it replaces the old index somehow
      if Dir[ dir + "/*_core.new.*" ].empty?
        Dir[ dir + "/*_core.*" ].each do |file|
          dest_file = file.split('.').insert(-2, 'new').join('.')
          sh "mv -f #{file} #{dest_file}"
        end
      end
    end
    last_value = hash_value[ :sync_at ]
    if last_value.nil? || last_value < 2.minutes.ago
      hash_value[ :sync_at ] = Time.now.utc
      UpdateSearchdIndices.call( sync_main_index_flag )
      hash_value[ :sync_main_index_flag ] = false
    end
  end
  hash_value
}

namespace :ts do
  
  namespace :ci do
    
    desc "Start Thinking Sphinx Central Indexing Service"
    task :start => :environment do
      fork do
        $0 = 'ts_ci_runner'
        Process.setsid
        Dir.chdir File.join( File.dirname(__FILE__), '..' )
        PidFile.store(  File.join( Rails.root.to_s + '/../../shared', '/log/ts_ci_runner.pid' ), Process.pid )
        File.umask 0000
        STDIN.reopen "/dev/null"
        STDOUT.reopen File.join( Rails.root.to_s + '/../../shared', '/log/ts_ci_runner.log' ), "a"
        STDERR.reopen STDOUT
        require 'delayed_job'
        Delayed::Worker.send( :include, DelayedWorkerPatch )
        ActiveRecord::Base.connection.reconnect!
        BackgroundServiceDB.connection.reconnect! # Due to fork and MySQL Gone Away
        Delayed::Worker.new(
         :min_priority => ENV['MIN_PRIORITY'],
         :max_priority => ENV['MAX_PRIORITY']
        ).start_with_block( &MainIndexRunner )
        puts "Service terminated successfully"
      end
      puts "Thinking Sphinx Central Indexing Service Started"
    end
    
    desc "Stop Thinking Sphinx Central Indexing Service"
    task :stop => :environment do
      $0 = 'ts_ci_stopper'
      pid_file = File.join( Rails.root.to_s + '/../../shared', '/log/ts_ci_runner.pid' )
      pid = PidFile.recall( pid_file )
      FileUtils.rm( pid_file ) rescue nil
      pid && Process.kill( "TERM", pid )
      puts "Thinking Sphinx Central Indexing Service Stopped"
    end
    
    desc "Restart Thinking Sphinx Central Indexing Service"
    task :restart => :environment do
      Rake::Task['ts:ci:stop'].invoke rescue
      Rake::Task['ts:ci:start'].invoke
    end
    
  end
  
end