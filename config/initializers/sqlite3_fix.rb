connection = ActiveRecord::Base.connection

def redefine_const( module_obj, constant_name, value )
  module_obj.send( :remove_const, constant_name )
  module_obj.send( :const_set, constant_name, value)
end

if connection.adapter_name.downcase =~ /sqlite/
  
  redefine_const( DB::Timestamp, :Day, connection.quote( DB::Timestamp::Day ).freeze )
  redefine_const( DB::Timestamp, :Hour, connection.quote( DB::Timestamp::Hour ).freeze )
  redefine_const( DB::Timestamp, :Minute, connection.quote( DB::Timestamp::Minute ).freeze )
  redefine_const( DB::Timestamp, :Second, connection.quote( DB::Timestamp::Second ).freeze )
  redefine_const( DB::Engine, :MyISAM, nil )
  redefine_const( DB::Engine, :InnoDB, nil )
  
  db = connection.instance_variable_get('@connection')
  
  db.create_function( 'CONCAT', -1 ) do |func, *values|
    func.result = values.collect{|x| String(x) }.inject(''){ |s,x| s << x }
  end
  
  db.create_function( 'POWER', 2 ) do |func, value1, value2|
    func.result = Float(value1)**Float(value2)
  end
  
  db.create_function( 'FLOOR', 1 ) do |func, value|
    func.result = Float(value).floor
  end
  
  db.create_function( 'UTC_TIMESTAMP', 0 ) do |func|
    func.result = Time.now.utc.to_s(:db)
  end
  
  db.create_function( 'TIMESTAMPDIFF', 3 ) do |func, value1, value2, value3|
    result = (DateTime.parse(String(value2)).to_time - DateTime.parse(String(value3)).to_time).to_i
    result = case( String(value1).upcase ) when 'HOUR' : result / 3600
      when 'MINUTE' : result / 60
      when 'DAY' : result / 86400
      else result end
    func.result =  result #"CAST(#{result} AS INTEGER)"
  end
  
  db.create_aggregate( 'GROUP_CONCAT', 1) do
    step do |func, value|
      func[:concat] ||= []
      func[:concat].push( String(value) ) unless value.null?
    end

    finalize do |func|
      func[:concat] ||= []
      func.result = func[:concat].join(',')
    end
  end
  
end