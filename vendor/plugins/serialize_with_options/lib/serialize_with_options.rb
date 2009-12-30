module SerializeWithOptions

  def serialize_with_options(set = :default, &block)
    configuration = read_inheritable_attribute(:configuration) || {}
    options       = read_inheritable_attribute(:options) || {}

    configuration[set] = Config.new.instance_eval(&block)

    write_inheritable_attribute :configuration, configuration
    write_inheritable_attribute :options, options

    include InstanceMethods
  end

  def serialization_configuration(set)
    configuration = read_inheritable_attribute(:configuration)
    conf = if configuration
      configuration[set] || configuration[:default]
    end

    conf.try(:dup) || { :methods => nil, :only => nil, :except => nil }
  end

  def serialization_options(set, object=nil)
    options = read_inheritable_attribute(:options)
    options[set] ||= returning serialization_configuration(set) do |opts|
      includes = opts.delete(:includes)
      
      if includes
        opts[:include] = includes.inject({}) do |hash, class_name|
          if class_name.is_a? Hash
            hash.merge(class_name)
          else
            begin
              klass = class_name.to_s.classify.constantize
              hash[class_name] = klass.serialization_configuration(set)
              hash[class_name][:include] = nil if hash[class_name].delete(:includes)
              hash
            rescue NameError
              hash.merge(class_name => { :include => nil })
            end
          end
        end
      end
      
    end
    write_inheritable_attribute :options, options
    options[set]
  end
  
  def serialization_options_with_mappings(object, options = {} )
    maps = options.delete(:map)
    map_includes = options.delete(:map_include)
    options[:only] = Array( options[:only] ) if options[:only]
    options[:procs] = []
    if maps
      options[:procs] += maps.keys.select{ |x| options[:only] ? options[:only].include?(x) : true }.inject( [] ) do |array, key|
        array.push( Proc.new{ |opts|  opts[:builder].tag!( key.to_s, object.send( maps[key].to_s )  ) } )
      end
    end
    if map_includes
      options[:procs] += map_includes.keys.select{ |x| options[:only] ? options[:only].include?(x) : true }.inject( [] ) do |array, key|
        array.push( Proc.new{ |opts|  object.send( map_includes[key].to_s, opts.merge( :root => key.to_s ) )  } )
      end
    end
    return options
  end

  class Config
    undef_method :methods
    Instructions = [:skip_instruct, :dasherize, :skip_types, :root_in_json, :map, :map_include, :root].freeze

    def initialize
      @data = { :methods => nil, :only => nil, :except => nil }
    end

    def method_missing(method, *args)
      @data[method] = Instructions.include?(method) ? args.first : args
      @data
    end
  end

  module InstanceMethods
    def to_xml(opts = {})
      set, opts = parse_serialization_options(opts)
      super( self.class.serialization_options_with_mappings( self, self.class.serialization_options(set).deep_merge(opts) ))
    end

    def to_json(opts = {})
      set, opts = parse_serialization_options(opts)
      super( self.class.serialization_options_with_mappings( self, self.class.serialization_options(set).deep_merge(opts) ))
    end

    private

    def parse_serialization_options(opts)
      if opts.is_a? Symbol
        set  = opts
        opts = {}
      else
        set  = opts.delete( :set ) || :default
      end

      [set, opts]
    end
  end
end
