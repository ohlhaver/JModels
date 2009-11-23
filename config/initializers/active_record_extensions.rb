class ActiveRecord::Base
  
  def self.select_attributes( *attributes )
    attributes.collect{ |x| Symbol === x ? "#{self.table_name}.#{x}" : x }.join(', ')
  end
  
  def to_csv( *attributes )
    attrs = attributes_before_type_cast
    attributes.collect{ |x| connection.quote( attrs[ x.to_s ] ) }.join(', ')
  end
  
end

class ActiveRecord::ConnectionAdapters::AbstractAdapter
  
  def quote_all( *args )
    args.collect{ |x| quote(x) }
  end
  
  def quote_and_merge( *args )
    quote_all( *args ).join(', ')
  end
  
end