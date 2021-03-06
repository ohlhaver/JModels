require_dependency 'serialize_with_options'

Numeric.class_eval do
  
  def to_xml( options = {} )
    return to_s unless options[:root] 
    require 'builder' unless defined?(Builder)
    options[:root]    ||= "value"
    options[:indent]  ||= 2
    options[:builder] ||= Builder::XmlMarkup.new( :indent => options[:indent])
    options[:builder].tag!( options[:root], self.to_s, options[:skip_types] ? {} : { :type => ( self.is_a?( Integer ) ? "integer" : "float" ) } )
  end
  
end

Time.class_eval do
  
  def to_xml( options = {} )
    return to_s unless options[:root] 
    require 'builder' unless defined?(Builder)
    options[:root]    ||= "value"
    options[:indent]  ||= 2
    options[:builder] ||= Builder::XmlMarkup.new( :indent => options[:indent])
    options[:builder].tag!( options[:root], self.to_datetime.to_s, options[:skip_types] ? {} : { :type => "datetime" } )
  end
  
end

TrueClass.class_eval do
  
  def to_xml( options = {} )
    return to_s unless options[:root] 
    require 'builder' unless defined?(Builder)
    options[:root]    ||= "value"
    options[:indent]  ||= 2
    options[:builder] ||= Builder::XmlMarkup.new( :indent => options[:indent])
    options[:builder].tag!( options[:root], self.to_s, options[:skip_types] ? {} : { :type => "boolean" } )
  end
  
end


FalseClass.class_eval do
  
  def to_xml( options = {} )
    return to_s unless options[:root] 
    require 'builder' unless defined?(Builder)
    options[:root]    ||= "value"
    options[:indent]  ||= 2
    options[:builder] ||= Builder::XmlMarkup.new( :indent => options[:indent])
    options[:builder].tag!( options[:root], self.to_s, options[:skip_types] ? {} : { :type => "boolean" } )
  end
  
end

String.class_eval do
  
  def to_xml( options = {} )
    return to_s unless options[:root]
    require 'builder' unless defined?(Builder)
    options[:indent]  ||= 2
    options[:builder] ||= Builder::XmlMarkup.new( :indent => options[:indent])
    options[:builder].tag!( options[:root], self.to_s, {} )
  end
  
end

NilClass.class_eval do
  
  def to_xml( options = {} )
    return to_s unless options[:root]
    require 'builder' unless defined?(Builder)
    options[:root]    ||= "value"
    options[:indent]  ||= 2
    options[:builder] ||= Builder::XmlMarkup.new( :indent => options[:indent])
    options[:builder].tag!( options[:root], "", :nil => true )
  end
  
end

ActiveRecord::Base.extend(SerializeWithOptions)