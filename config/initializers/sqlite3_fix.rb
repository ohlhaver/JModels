connection = ActiveRecord::Base.connection
if connection.adapter_name.downcase =~ /sqlite/
  
  db = connection.instance_variable_get('@connection')
  
  db.create_function( 'CONCAT', -1 ) do |func, *values|
    func.result = values.collect{|x| String(x) }.inject(''){ |s,x| s << x }
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