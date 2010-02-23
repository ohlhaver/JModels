class Preference < ActiveRecord::Base
  
  serialize_with_options do
    dasherize false
    map_include :search_language_ids  => :search_languages_ids_for_serialize
    except  :id, :owner_id, :owner_type
  end
  
  
  serialize_with_options( :long ) do
    column_names = [ :author_email, :blog, :cluster_preview, :default_language_id,
      :default_sort_criteria, :default_time_span, :headlines_per_cluster_group,
      :image, :interface_language_id, :opinion, :per_page, :region_id,
      :subscription_type, :topic_email, :video, :search_language_ids ]
    dasherize false
    map_include column_names.inject({}){ |h,c| h.merge!( c => "#{c}_serialize".to_sym ) }
    except *( column_names + [ :id, :owner_id, :owner_type ] )
  end
  
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
      :language_id => :LanguageValues,
      :interface_language_id => :LanguageValues,
      :default_language_id => :LanguageValues,
      :cluster_preview => :ClusterPreviewValues,
      :headlines_per_cluster_group => :ClusterGroupValues,
      :per_page => :PerPageValues,
      :region_id => :RegionValues,
      :default_region_id => :RegionValues,
      :search_language_id => :LanguageValues,
      :search_language_ids => :LanguageValues,
      :homepage_boxes => :HomePageBoxesValues,
      :top_stories_cluster_group => :TopStoriesClusterGroupValues,
      :category_id => :CategoryValues
    }
    
    CategoryValues = Category.collection( :default ).collect{ |category|
      { :name => "prefs.category.#{category.name.underscore}", :code => category.code.downcase.to_sym, :id => category.id }
    }
    
    TopStoriesClusterGroupValues = Category.collection( :top_stories_cluster_group ).collect{ |category|
      { :name => "prefs.category.#{category.name.underscore}", :code => category.code.downcase.to_sym, :id => category.id }
    }
    
    HomePageBoxesValues = [
      { :name => 'prefs.homepage.top_stories',    :code => :top_stories_cluster_group, :id => 0 },
      { :name => 'prefs.homepage.cluster_groups', :code => :cluster_groups, :id => 1 },
      # { :name => 'prefs.homepage.top_authors',    :code => :top_authors, :id => 2 },
      { :name => 'prefs.homepage.my_authors',     :code => :my_authors, :id => 3 },
      { :name => 'prefs.homepage.my_topics',      :code => :my_topics, :id => 4 }
    ]
  
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
    
    RegionValues = Region.find(:all, :conditions => { :code => ['DE', 'AT', 'CH', 'INT'] }, :order => 'id' ).collect{ |x|
      { :name => "prefs.country.#{x.code.downcase}", :code => x.code, :id => x.id }
    }
    
    ClusterPreviewValues = [ { :name => 1, :code => 1, :id => 1 }, { :name => 3, :code => 3, :id => 3 } ]
    
    ClusterGroupValues = [ { :name => 1, :code => 1, :id => 1 }, 
      { :name => 2, :code => 2, :id => 2 },
      { :name => 3, :code => 3, :id => 3 },
      { :name => 4, :code => 4, :id => 4 },
      { :name => 5, :code => 5, :id => 5 },
      { :name => 6, :code => 6, :id => 6 }
    ]
    
    PerPageValues = [ 
      { :name => 5, :code => 5, :id => 5 }, 
      { :name => 10, :code => 10, :id => 10 },
      { :name => 15, :code => 15, :id => 15 },
      { :name => 20, :code => 20, :id => 20 },
      { :name => 25, :code => 25, :id => 25 },
      { :name => 30, :code => 30, :id => 30 }
    ]
    
    DefaultValues = {
      #:default_language_id => LanguageValues.select{ |x| x[:code] == 'en' }.first.try(:[], :id),
      #:interface_language_id => LanguageValues.select{ |x| x[:code] == 'en' }.first.try(:[], :id),
      :default_time_span => 1.month.to_i,
      :default_sort_criteria => 0,
      :image => 1,
      :video => 2,
      :blog => 2,
      :opinion => 2,
      :topic_email => 0,
      :author_email => 2,
      :cluster_preview => 3,
      :headlines_per_cluster_group => 2,
      :subscription_type => 0,
      :per_page => 10,
      #:search_language_ids => { LanguageValues.select{ |x| x[:code] == 'en' }.first.try(:[], :id) => '1' },
      :region_id => RegionValues.select{ |x| x[:code] == 'INT' }.first.try(:[], :id )
    }
    
  end
  
  unless method_defined?( :initialize_with_default_values )
    
    def initialize_with_default_values( attributes = {} )
      attributes ||= {}
      initialize_without_default_values( attributes.reverse_merge( DefaultValues ) )
    end
    
    alias_method_chain :initialize, :default_values
    
  end
  
  class << self
    
    def default_language_id_for_region_id( region_id )
      language_code = Region::DefaultLanguage[ Preference.select_value_by_name_and_id( :region_id, region_id ).try( :[], :code ) ] || 'en'
      Preference.select_value_by_name_and_code( :language_id, language_code ).try(:[], :id ) || default_language_id
    end
    
    def default_region_id
      DefaultValues[ :region_id ]
    end
    
    def default_language_id
      default_language_id_for_region_id( default_region_id )
    end
    
    def select_all( preference_name )
      constant_name = Map[ preference_name.try(:to_sym) ]
      return [] if constant_name.nil?
      self.const_get( constant_name )
    end
    
    def select_all_homepage_cluster_group( region_id=nil, language_id=nil)
      region_id = select_value_by_name_and_id( :region_id, region_id.to_i ).try( :[], :id ) || default_region_id
      language_id = select_value_by_name_and_id( :language_id, language_id.to_i ).try( :[], :id ) || default_language_id_for_region_id( region_id )
      tag = "Region:#{region_id}:#{language_id}"
      cluster_groups = ClusterGroup.for_select( :tag => tag )
      cluster_groups.collect{ |x| { :id => x.last, :name => "prefs.category.#{x.first.underscore}", :code => x.first.underscore } }
    end
    
    def for_select( preference_name )
      constant_name = Map[ preference_name.try(:to_sym) ]
      return [] if constant_name.nil?
      preferences_array = self.const_get( constant_name )
      preferences_array.collect{ |x| [ ( x[:name].is_a?( String) ? I18n.t( x[:name] ) : x[:name] ), x[:id] ] }
    end

    def select_value_by_name_and_code( preference_name, code )
      constant_name = Map[ preference_name.try(:to_sym) ]
      return nil if constant_name.nil?
      preferences_array = self.const_get( constant_name )
      preferences_array.select{ |x| x[:code] == code }.first
    end

    def select_value_by_name_and_id( preference_name, id )
      constant_name = Map[ preference_name.try(:to_sym) ]
      return nil if constant_name.nil?
      preferences_array = self.const_get( constant_name )
      preferences_array.select{ |x| x[:id] == id }.first
    end
    
  end
  
  belongs_to :owner, :polymorphic => true
  before_save :save_search_language_ids
  before_create :create_homepage_box_prefs
  
  # virtual attribute default_edition_id
  
  def default_edition_id
    rc = self.class.select_value_by_name_and_id( :region_id, self.region_id ).try(:[], :code)
    lc = self.class.select_value_by_name_and_id( :language_id, self.default_language_id ).try( :[], :code )
    rc && lc ? "#{rc.downcase}-#{lc}" : "int-en"
  end
  
  def default_edition_id=(edition_string)
    rc, lc = edition_string.split("-")
    return unless ( lc && rc )
    self.region_id = self.class.select_value_by_name_and_code( :region_id, rc.upcase ).try(:[], :id)
    self.default_language_id = self.class.select_value_by_name_and_code( :language_id, lc ).try(:[], :id)
  end
  
  def reset_search_lang_prefs!
    @search_lang_prefs = Array.new
  end
  
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
  
  def search_languages_ids_for_serialize( options = {} )
    search_language_ids( :reload ).to_xml( options )
  end
  
  def save_search_language_ids
    @search_lang_prefs.try(:each){ |attrs| 
      mvp = MultiValuedPreference.preference(:search_languages).create( 
        attrs.merge( :owner_id => self.owner_id, :owner_type => self.owner_type ) 
      )
      logger.info mvp.errors.full_messages if mvp.errors.any?
    }
    @search_lang_prefs.try(:clear)
  end
  
  def create_homepage_box_prefs
    # Preferences are created by default ( global preferences and are not customized per edition )
    Preference.select_all( :homepage_boxes ).collect do |pref|
      mvp = MultiValuedPreference.preference(:homepage_boxes).create( :owner_id => self.owner_id, :owner_type => self.owner_type, :value => pref[:id] )
      logger.info mvp.errors.full_messages if mvp.errors.any?
      mvp
    end
  end
  
  def create_top_section_prefs
    Preference.select_all( :top_stories_cluster_group ).collect do |pref|
      mvp = MultiValuedPreference.preference( :top_stories_cluster_group ).create( :owner_id => self.owner_id, :owner_type => self.owner_type, :value => pref[:id] )
      logger.info mvp.errors.full_messages if mvp.errors.any?
      mvp
    end
  end
  
  unless method_defined?( :method_missing_with_serialize )
    
    def method_missing_with_serialize( sym, *args, &block )
      if match = sym.to_s.match(/^(.+)_serialize$/)
        value = send( match[1] )
        value = value.is_a?( Array ) ? value.collect{ |x| self.class.select_value_by_name_and_id( match[1], x ) } : self.class.select_value_by_name_and_id( match[1], value )
        options = args.first
        value.to_xml( options.merge( :root => match[1] ), &block )
      else
        method_missing_without_serialize( sym, *args, &block )
      end
    end
    
    alias_method_chain :method_missing, :serialize
    
  end
  
end