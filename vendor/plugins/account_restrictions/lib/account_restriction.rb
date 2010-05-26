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
          skip_account_restriction = f.delete(:without_account_restriction)
        end
        hash = { :find => {} }
        current_scoped_methods.inject(hash) do | hash, (method, params)|
          hash[method] = params
        end if current_scoped_methods
        hash[:find].merge!( :user => user ) if user
        hash[:find].merge!( :without_account_restriction => skip_account_restriction ) unless skip_account_restriction.nil?
        self.scoped_methods << hash if user || skip_account_restriction != nil
        begin
          with_scope_without_account_restriction( method_scoping, action, &block )
        ensure
          self.scoped_methods.pop if user
        end
      end
      
      def find_with_account_restriction( *args )
        options = args.extract_options!
        user = options.delete(:user) || scope(:find, :user)
        skip_account_restriction = options.delete(:without_account_restriction) || scope( :find, :without_account_restriction)
        if user && !user.power_plan? && !skip_account_restriction
          user_prefs_count = user.topic_count + user.source_count + user.author_count
          options.merge!( :limit => 2 ) if user_prefs_count > 5
        end
        #options.merge!( :limit => 1 ) unless skip_account_restriction || ( user && user.power_plan? )
        args.push( options )
        find_without_account_restriction( *args )
      end
      
      def count_with_account_restriction( *args )
        options = args.extract_options!
        user = options.delete(:user) || scope(:find, :user)
        skip_account_restriction = options.delete(:without_account_restriction) || scope( :find, :without_account_restriction)
        args.push( options )
        count = count_without_account_restriction( *args )
        if user && !user.power_plan? && !skip_account_restriction
          user_prefs_count = user.topic_count + user.source_count + user.author_count
          count = count > 2 ? 2 : count if user_prefs_count > 5
        end
        return count
      end
    end
    
    module InstanceMethods
      
      def validate_account_restrictions
        account_user = self.send( self.class.user_account_restrictions[:user] )
        association = self.class.user_account_restrictions[:association]
        user_prefs_count = account_user.topic_count + account_user.source_count + account_user.author_count
        errors.add( :account, :restricted ) if account_user.nil? || ( !account_user.power_plan? && user_prefs_count >= 5 )
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