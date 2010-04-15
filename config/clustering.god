God.watch do |w|
  w.name = "clustering"
  w.uid = 'jurnalo'
  w.gid = 'jurnalo'
  w.group = "background_processes"
  w.interval = 60.seconds # default
  w.dir = "/home/jurnalo/apps/JModels/current"
  w.start = "/opt/ruby/bin/rake clustering:start RAILS_ENV=production"
  w.stop = "/opt/ruby/bin/rake clustering:stop RAILS_ENV=production"
  w.restart = "/opt/ruby/bin/rake clustering:restart RAILS_ENV=production"
  w.start_grace = 10.seconds
  w.restart_grace = 10.seconds
  w.pid_file = "/home/jurnalo/apps/JModels/current/log/clustering.pid"
  w.behavior(:clean_pid_file)
  
  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 60.seconds
      c.running = false
    end
  end
  
  # w.restart_if do |restart|
  #   restart.condition(:memory_usage) do |c|
  #     c.above = 60.megabytes
  #     c.times = [ 2, 5 ] # 3 out of 5 intervals
  #   end
  #   # restart.condition(:cpu_usage) do |c|
  #   #   c.above = 50.percent
  #   #   c.times = 5
  #   # end
  # end
  
  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 10.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end
end