class Preference < ActiveRecord::Base
  
  unless defined?( Preference::Map )
    
    Map = { 
      :topic_email => :EmailValues, 
      :author_email => :EmailValues,
      :author => :Preference1Values, 
      :source => :Preference1Values, 
      :blog => :Preference2Values, 
      :video => :Preference2Values, 
      :opinion => :Preference2Values,
      :sort_criteria => :SortValues, 
      :default_sort_criteria => :SortValues,
      :image => :ImageValues, 
      :subscription_type => :SubscriptionValues,
      :time_span => :TimeRangeValues, 
      :default_time_span => :TimeRangeValues,
      :interface_language_id => :LanguageValues,
      :default_language_id => :LanguageValues,
      :cluster_preview => :ClusterPreviewValues,
      :per_page => :PerPageValues
    }
  
    EmailValues = [ 
      { :name => 'prefs.email.off',         :code => :off,          :id => 0 },
      { :name => 'prefs.email.immediately', :code => :immediately,  :id => 1 },
      { :name => 'prefs.email.daily',       :code => :daily,        :id => 2 },
      { :name => 'prefs.email.weekly',      :code => :weekly,       :id => 3 }
    ]
  
    Preference1Values = [
      { :name => 'prefs.val.ban',       :code => :ban,      :id => 0 },
      { :name => 'prefs.val.low',       :code => :low,      :id => 1 },
      { :name => 'prefs.val.medium',    :code => :medium,   :id => 2 },
      { :name => 'prefs.val.high',      :code => :high,     :id => 3 }
    ]
  
    Preference2Values = [
      { :name => 'prefs.val.none',    :code => :no,       :id => 0 },
      { :name => 'prefs.val.low',     :code => :low,      :id => 1 },
      { :name => 'prefs.val.neutral', :code => :neutral,  :id => 2 },
      { :name => 'prefs.val.high',    :code => :high,     :id => 3 },
      { :name => 'prefs.val.only',    :code => :only,     :id => 4 }
    ]
  
    ImageValues = [
      { :name => 'prefs.image.off', :code => :off,  :id => 0 },
      { :name => 'prefs.image.on',  :code => :on,   :id => 1 }
    ]
  
    SortValues = [
      { :name => 'prefs.sort.relevance',          :code => :relevance,            :id => 0 },
      { :name => 'prefs.sort.cluster.relevance',  :code => :relevance_clustered,  :id => 1 },
      { :name => 'prefs.sort.time',               :code => :time,                 :id => 2 },
      { :name => 'prefs.sort.cluster.time',       :code => :time_clustered,       :id => 3 }
    ]
  
    TimeRangeValues = [
      { :name => 'prefs.time_span.last_hour',  :code => :last_hour,  :id => 1.hour.to_i },
      { :name => 'prefs.time_span.last_day',   :code => :last_day,   :id => 1.day.to_i  },
      { :name => 'prefs.time_span.last_week',  :code => :last_week,  :id => 1.week.to_i },
      { :name => 'prefs.time_span.last_month', :code => :last_month, :id => 1.month.to_i }
    ]
  
    #all articles, only free articles, only articles that don’t require login
    SubscriptionValues = [
      { :name => 'prefs.subscription.all',      :code => :all,      :id => 0 },
      { :name => 'prefs.subscription.free',     :code => :free,     :id => 1 },
      { :name => 'prefs.subscription.no_login', :code => :no_login, :id => 2 }
    ]
    
    LanguageValues = Language.find(:all, :conditions => { :code => ['de', 'en'] }, :order => 'code ASC').collect{ |x| 
      { :name => "prefs.lang.#{x.name.downcase}", :code => x.code, :id => x.id }
    }
    
    ClusterPreviewValues = [ { :name => 1, :code => 1, :id => 1 }, { :name => 3, :code => 3, :id => 3 } ]
    
    PerPageValues = [ { :name => 10, :code => 10, :id => 10 }, { :name => 20, :code => 20, :id => 20 }, { :name => 30, :code => 30, :id => 30 },
      { :name => 40, :code => 40, :id => 40 },  { :name => 50, :code => 50, :id => 50 } ]
    
    DefaultValues = {
      :default_language_id => LanguageValues.first.try(:[], :id),
      :interface_language_id => LanguageValues.first.try(:[], :id),
      :default_time_span => 1.month.to_i,
      :default_sort_criteria => 0,
      :image => 1,
      :video => 2,
      :blog => 2,
      :opinion => 2,
      :topic_email => 0,
      :author_email => 2,
      :cluster_preview => 3,
      :subscription_type => 0,
      :per_page => 10,
      :search_language_ids => { LanguageValues.first.try(:[], :id) => '1' }
    }
    
  end
  
  class << self
    
    unless method_defined?( :new_with_default_values )
      
      def new_with_default_values( attributes = {} )
        attributes ||= {}
        new_without_default_values( attributes.reverse_merge( DefaultValues ) )
      end
      
      def create_with_default_values( attributes = {} )
        create_without_default_values( attribtues.reverse_merge( DefaultValues ) )
      end
      
      alias_method_chain :new, :default_values
      alias_method_chain :create, :default_values
    
    end
    
    def for_select( preference_name )
      constant_name = Map[ preference_name.try(:to_sym) ]
      return [] if constant_name.nil?
      preferences_array = self.const_get( constant_name )
      preferences_array.collect{ |x| [ ( x[:name].is_a?( String) ? I18n.t( x[:name] ) : x[:name] ), x[:id] ] }
    end

    def value_by_name_and_code( preference_name, code )
      constant_name = Map[ preference_name.try(:to_sym) ]
      return nil if constant_name.nil?
      preferences_array = self.const_get( constant_name )
      preferences_array.select{ |x| x[:code] == code }.first
    end

    def value_by_name_and_id( preference_name, id )
      constant_name = Map[ preference_name.try(:to_sym) ]
      return nil if constant_name.nil?
      preferences_array = self.const_get( constant_name )
      preferences_array.select{ |x| x[:id] == id }.first
    end
    
  end
  
  belongs_to :owner, :polymorphic => true
  
  def search_language_ids=( language_ids )
    if language_ids.is_a?( Hash )
      @search_lang_prefs ||= Array.new
      language_ids.each_pair{ |l_id, status| 
        @search_lang_prefs << { :value => l_id, :status => status }
      }
    end
    @search_lang_prefs
  end
  
  def search_language_ids( reload = false )
    @cached_search_language_ids = nil if reload
    @cached_search_language_ids ||= MultiValuedPreference.preference( :search_languages ).owner_id_and_type( owner_id, 
      owner_type ).all( :order => 'position' ).collect{ |x| x.value }
    group = @search_lang_prefs.try(:group_by){ |x| x[:status].to_s } || {}
    group.each_pair{ |k,v| v.collect!{ |x| x[:value] } }
    @cached_search_language_ids + Array( group[ "1" ] ) - Array( group[ "0" ] )
  end
  
  def search_language_id_exists?( language_id )
    search_language_ids.include?( language_id )
  end
  
  before_save :save_search_language_ids
  
  unless method_defined?( :method_missing_with_field_code )
    def method_missing_with_field_code( method_id, *args )
      attribute = method_id.to_s.match(/(.+)_code$/).try(:[], 1)
      if attribute && self.respond_to?( attribute ) && args.empty? then
        self.class.value_by_name_and_id( attribute, send( attribute ) ).try( :[], :code )
      else
        method_missing_without_field_code( method_id, *args )
      end
    end
    alias_method_chain :method_missing, :field_code
  end
  
  protected
  
  def save_search_language_ids
    @search_lang_prefs.try(:each){ |attrs| 
      mvp = MultiValuedPreference.preference(:search_languages).create( 
        attrs.merge( :owner_id => self.owner_id, :owner_type => self.owner_type ) 
      )
      logger.info mvp.errors.full_messages
    }
    @search_lang_prefs.clear
  end
  
end