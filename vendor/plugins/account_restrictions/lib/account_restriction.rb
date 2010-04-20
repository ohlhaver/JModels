module ActiveRecord
  
  module UserAccountRestriction
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      
      def activate_user_account_restrictions( options = {} )
        raise ArgumentError if options[:user].blank? || options[:association].blank?
        
        class_eval do
          
          cattr_accessor :user_account_restrictions
          self.user_account_restrictions ||= Hash.new
          self.user_account_restrictions[:user] = options[:user]
          self.user_account_restrictions[:association] = options[:association]
          validate_on_create :validate_account_restrictions
          class << self
            include RestrictionMethods
            alias_method_chain :find, :account_restriction
            alias_method_chain :count, :account_restriction
            alias_method_chain :with_scope, :account_restriction
          end
          include InstanceMethods
        end  
      end
      
    end
    
    module RestrictionMethods
                             
      def with_scope_with_account_restriction( method_scoping = {}, action = :merge, &block )
        method_scoping = method_scoping.method_scoping if method_scoping.respond_to?(:method_scoping)
        # Dup first and second level of hash (method and params).
        method_scoping = method_scoping.inject({}) do |hash,   (method, params)|
          hash[method] = (params == true) ? params : params.  dup
          hash                                                
        end
        user = nil
        if f = method_scoping[:find]
          user = f.delete(:user)
        end
        if user
          hash = { :find => { :user => user } }
          current_scoped_methods.inject(hash) do | hash, (method, params)|
            hash[method] = params
          end if current_scoped_methods
          hash[:find].merge!( :user => user )
          self.scoped_methods << hash
        end
        begin
          with_scope_without_account_restriction( method_scoping, action, &block )
        ensure
          self.scoped_methods.pop if user
        end
      end
      
      def find_with_account_restriction( *args )
        options = args.extract_options!
        user = options.delete(:user) || scope(:find, :user)
        options.merge!( :limit => 1 ) unless user && user.power_plan?
        args.push( options )
        find_without_account_restriction( *args )
      end
      
      def count_with_account_restriction( *args )
        options = args.extract_options!
        user = options.delete(:user) || scope(:find, :user)
        args.push( options )
        count = count_without_account_restriction( *args )
        user && user.power_plan? ? count : ( count > 0 ? 1 : 0 )
      end
    end
    
    module InstanceMethods
      
      def validate_account_restrictions
        account_user = self.send( self.class.user_account_restrictions[:user] )
        association = self.class.user_account_restrictions[:association]
        errors.add( :account, :restricted ) if account_user.nil? || ( !account_user.power_plan? && account_user.send(association).count > 0 )
      end
      
      protected( :validate_account_restrictions )
      
    end
    
    module AssociationMethods
      
      def find_in_batches( *args )
        options = args.extract_options!
        options[:user] = proxy_owner
        args.push( options )
        super(*args)
      end
      
      def find_each( *args )
        options = args.extract_options!
        options[:user] = proxy_owner
        args.push( options )
        super(*args)
      end
      
      def paginate( *args )
        options = args.extract_options!
        options[:user] = proxy_owner
        args.push( options )
        super(*args)
      end
      
      def all( *args )
        options = args.extract_options!
        options[:user] = proxy_owner
        args.push( options )
        super(*args)
      end

      def find( *args )
        options = args.extract_options!
        options[:user] = proxy_owner
        args.push( :all ) if args.empty?
        args.push( options )
        super(*args)
      end

      def count( *args )
        options = args.extract_options!
        options[:user] = proxy_owner
        args.push( :all ) if args.empty?
        args.push( options )
        super(*args)
      end

    end
    
  end
  
end