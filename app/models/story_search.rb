class Treetop::Runtime::SyntaxNode
  def eval(env={})
    text_value
  end
end

module SQL
  class BinaryOperation < Treetop::Runtime::SyntaxNode
    def eval(env={})
      operator.apply(operand_1.eval(env), operand_2.eval(env))      
    end
  end
  class UnaryOperation < Treetop::Runtime::SyntaxNode
    def eval( env={})
      operator.apply( operand.eval(env) )
    end
  end
  class QueryString < Treetop::Runtime::SyntaxNode
    def eval(env={})
      if query.text_value.blank?
        value = term.eval
        value.blank? ? [] : [ term.eval ]
      else
        result = query.query.eval( env )
        if env[:csv] && !query.delim.eval.match(/,/)
          first = result.shift
          first.gsub!(/\"|\'/, '') if first
          value = first ? "#{term.eval} #{first}" : term.eval
          value.blank? ? result : result.unshift( value.dump )
        else
          result.unshift( term.eval )
        end
      end
    end
  end
end

class StorySearch
  
  attr_accessor :params
  attr_accessor :user
  attr_accessor :mode # :serialize, :simple, :advance
  attr_reader :options
  attr_reader :facet_options
  attr_reader :string
  
  def initialize( user = user, mode = :simple, params = {} )
    self.params = HashWithIndifferentAccess.new( params )
    self.mode = mode
    self.user = user
    if mode != :serialize
      @parser = SQLParser.new
      populate_options
      populate_string
    end
  end
  
  def populate_options
    @options = { :with => { :master_id => 0 }, :without => {}, :match_mode => :extended }
    case( self.mode ) when :author, :source
      send( "populate_#{self.mode}_options" )
    else
      populate_search_options
    end
  end
  
  def populate_string
    @string = case( mode ) when :advance, :topic : populate_advance_search_string
    else ( @parser.parse( params[:q] || '' ).try(:root).try(:eval) || [] ).join(' ') end
  end
  
  def facets
    @facet_options ? Story.facets( string, facet_options ) : {}
  end
  
  def results
    relevance = options.delete( :relevance )
    options[:set_select] = "*, #{relevance} AS relevance" if relevance
    stories = Story.search( string, options.merge( :page => page, :per_page => per_page, :include => [ :source, :authors ] ) )
    options.delete( :set_select ) if relevance
    options[:relevance] = relevance if relevance
    stories.facets = self.facets
    populate_cluster_info( stories )
    return stories
  end
  
  def to_hash
    { :options => options, :string => string }
  end
  
  def self.from_hash( user, params = {}, hash = {} )
    object = new( user, :serialize, params )
    object.send( :instance_variable_set, '@options', hash[:options] || {} )
    object.send( :instance_variable_set, '@string',  hash[:string] || '' )
    yield( object ) if block_given?
    return object
  end
  
  def inspect
    "<StorySearch:#{object_id} #{string}>"
  end
  
  protected
  
  def populate_author_options
    self.options[:without].merge!( :author_ids => 0 )
    self.params[:sort_criteria] = 2
    add_filter_author_ids
    add_sort_criteria 
    add_time_span
  end
  
  def populate_source_options
    self.options[:without].merge!( :source_id => 0 )
    self.params[:sort_criteria] = 2
    add_filter( :source_id )
    add_sort_criteria 
    add_time_span
    add_filter( :category_id )
  end
  
  def populate_search_options
    add_filter_author_ids
    add_sort_criteria 
    add_time_span
    add_filter( :category_id )
    add_filter_region_id
    add_filter( :source_id )
    add_subscription_type
    add_language_ids
    @facet_options = { :with => self.options[:with].dup, 
      :without => self.options[:without].dup, 
      :match_mode => :extended, 
      :facets => [:is_opinion, :is_blog, :is_video] 
    }
    @facet_options.merge!( :group_function => options[:group_function], :group_by => options[:group_by] ) if options[:group_by]
    add_blog_pref
    add_video_pref
    add_opinion_pref
  end
  
  def populate_cluster_info( stories )
    group_ids_map = stories.results[:matches].inject({}){ |map,x| map[ x[:attributes]['story_id'] ] = x[:attributes]['group_id']; map }
    group_ids = group_ids_map.values.select(&:nonzero?).uniq
    if group_ids.any?
      story_groups = StoryGroup.all( :conditions => { :id => group_ids } )
      StoryGroupArchive.all( :conditions => { :group_id => group_ids } ).inject( story_groups ){ |col, item| col.push( item ) }
      if clustered?
        StoryGroup.populate_stories_to_serialize( user, story_groups, per_cluster - 1, group_ids_map.keys )
      else
        story_groups.each{ |group| group.stories_to_serialize = [] }
      end
      story_group_map = story_groups.inject({}){ |map,grp| map[grp.id] = grp; map }
      stories.each{ |story| story.group_to_serialize = story_group_map[ group_ids_map[ story.id ] ] }
    end
  end
  
  def clustered?
    @clustered == true
  end
  
  def page
    p = Integer( params[:page] || 1 ) rescue 1
    params[:preview].to_s == '1' ? 1 : p
  end
  
  def per_page
    @per_page ||= user.try( :preference ).try( :per_page ) || 10
    pp = Integer( params[:per_page] || @per_page ) rescue 10
    params[:preview].to_s == '1' ? per_cluster_group : pp
  end
  
  #public private paid
  def add_subscription_type
    attr_value = column_eval( :subscription_type ) || user.try( :preference ).try( :subscription_type )
    case ( attr_value ) when '1', 1
      options[:with].merge!( :subscription_type => [ 0, 1 ] )
    when '2', 2
      options[:with].merge!( :subscription_type => [ 0 ] )
    end
  end
  
  def add_filter( attr_name )
    attr_value = Array( column_eval( "#{attr_name}s".to_sym ) || column_eval( attr_name ) )
    attr_value.collect!{ |x| x.to_i }
    options[:with].merge!( attr_name => attr_value ) unless attr_value.blank?
  end
  
  def add_filter_author_ids
    params[:sort_criteria] = 2 if params[:sort_criteria].blank? && mode == :author
    case( column_eval( :author_ids ) ) when 'all'
      params[:author_ids] = self.user ? by_user_authors : 0
    end
    attr_value = Array( column_eval( :author_ids ) || column_eval( :author_id ) )
    attr_value.collect!{ |x| x.to_i }
    options[:with].merge!( :author_ids => attr_value ) unless attr_value.blank?
  end
  
  def add_filter_region_id
    region_id = column_eval( :region_id )
    region_id = nil if region_id == -1 
    if region_id 
      region = Region.find( :first, :conditions => { :id => region_id } )
      source_ids = region.sources.collect( &:id )
      options[:with].merge!( :source_id => source_ids ) if source_ids
    end
  end
  
  def add_sort_criteria
    sort_criteria = column_eval( :sort_criteria ) ||  user.try( :preference ).try( :default_sort_criteria ) || Preference.select_value_by_name_and_code( :sort_criteria, :relevance )[ :id ]
    options[:without].merge!( :ban_user_ids => user.id ) if self.user
    case( sort_criteria ) when "2", 2
      options.merge!(  :sort_mode => :desc, :order => :created_at )
    when "3", 3
      @clustered = true
      options.merge!( :group_by => 'cluster_id', :group_function => :attr, :group_clause => 'created_at DESC', :order => 'created_at DESC', :sort_mode => :extended )
    when "1", 1
      @clustered = true
      options.merge!( :relevance => relevance, :group_function => :attr, :group_by => 'cluster_id', :group_clause => 'relevance DESC', :order => 'relevance DESC', :sort_mode => :extended )
    else
      options.merge!( :relevance => relevance, :sort_mode => :extended, :order => 'relevance DESC' )
    end
  end
  
  def relevance
    order = "@weight * (100/POW( 1 + IF( NOW() < created_at, 0, NOW() - created_at ), 0.33 ) ) * quality_rating" # sphinx_score * age * quality_rating
    if @user && ( @user.author_subscriptions.count > 0 || @user.source_subscriptions.count > 0 )
      "#{order} * 
        IF( IN( source_high_user_ids, #{@user.id} ), IF( default_author_rating < 0, 3/quality_rating, (3 + default_author_rating)/(2*quality_rating) ), 1 ) *
        IF( IN( source_normal_user_ids, #{@user.id} ), IF( default_author_rating < 0, 2/quality_rating, (2 + default_author_rating)/(2*quality_rating) ), 1 ) *
        IF( IN( source_low_user_ids, #{@user.id} ), IF( default_author_rating < 0, 1/quality_rating, (1 + default_author_rating)/(2*quality_rating) ), 1 ) *
        IF( IN( author_high_user_ids, #{@user.id} ), 3/quality_rating, 1 ) * 
        IF( IN( author_normal_user_ids, #{@user.id} ), 2/quality_rating, 1 ) *
        IF( IN( author_low_user_ids, #{@user.id} ), 1/quality_rating, 1 )".gsub(/\n|\r/, ' ').squeeze(' ')
    else
      order
    end
  end
  
  def add_time_span
    return if column_eval( :time_span ) == 'skip'
    custom_time_range = column_eval( :custom_time_span )
    if custom_time_range && custom_time_range.is_a?( Range ) && custom_time_range.first.is_a?( Time ) && custom_time_range.last.is_a?( Time )
      options[:with].merge!( :created_at => custom_time_range )
    else
      timespan = Preference.select_value_by_name_and_code( :time_span, column_eval( :time_span ).try( :to_sym ) ) || user.try( :preference ).try( :default_time_span ) || Preference.select_value_by_name_and_code( :time_span, :last_month )[:id ]
      start_time ||= timespan.seconds.ago
      options[:with].merge!( :created_at => ( (start_time)..(Time.now.utc) ) )
    end
  end
  
  def add_language_ids
    language_ids = column_eval( :language_id )
    language_ids = ( language_ids.blank? ? nil : Integer( language_ids ) rescue nil )
    language_ids ||= user.try( :preference ).try( :search_language_ids ) || Preference.default_language_id_for_region_id( column_eval( :region_id ) || -1 )
    options[:with].merge!( :language_id => language_ids )
  end
  
  def set_vob_pref( attr_name, attr_value )
    case attr_value  when "0", 0
      self.options[:with].merge!( attr_name => 0 )
    when "1", 1
      self.options[:relevance].send( :<<, "*IF( #{attr_name} = 0, 2, 0.5)" ) if self.options[:relevance]
    when "3", 3
      self.options[:relevance].send( :<<, "*IF( #{attr_name} = 1, 2, 0.5)" ) if self.options[:relevance]
    when "4", 4
      self.options[:with].merge!( attr_name => 1 )
    end
  end
  
  def add_blog_pref
    blog_pref = column_eval( :blog ) || user.try( :preference ).try( :blog )
    set_vob_pref( :is_blog, blog_pref )
  end
  
  def add_video_pref
    video_pref = column_eval( :video ) || user.try( :preference ).try( :video )
    set_vob_pref( :is_video, video_pref )
  end

  def add_opinion_pref
    opinion_pref = column_eval( :opinion ) || user.try( :preference ).try( :opinion )
    set_vob_pref( :is_opinion, opinion_pref )
  end
  
  def search_any_terms
    terms = ( @parser.parse( column_eval( :search_any ).to_s ).try( :root ).try( :eval ) || [] )
    terms = terms.size > 1 ? "( #{terms.join(' | ')} )" : terms.first
    Array( terms.blank? ? nil : terms )
  end
  
  def search_all_terms
    @parser.parse( column_eval( :search_all ).to_s ).try( :root ).try( :eval ) || []
  end
  
  def search_exact_phrase_terms
    @parser.parse( column_eval( :search_exact_phrase ).to_s ).try( :root ).try( :eval, :csv => true ) || []
  end
  
  def search_except_terms
    ( @parser.parse( column_eval( :search_except ).to_s ).try( :root ).try( :eval ) || [] ).collect{ |x| "!(#{x})" }
  end
  
  def populate_advance_search_string
    terms = search_any_terms + search_all_terms + search_exact_phrase_terms + search_except_terms
    ( terms.size > 1 ? "( #{terms.join(' & ')} )" : terms.first ) || ""
  end
  
  def column_eval( column_name )
    value = params[ column_name ]
    value.blank? ? nil : value
  end
  
  def by_user_authors
    self.user.author_subscriptions.subscribed.all( :select => 'author_id' ).collect( &:author_id )
  end
  
  def per_cluster_group
    Integer( params[:per_cluster_group] || @user.try(:preference).try( :headlines_per_cluster_group ) || 2 ) rescue 2
  end
  
  def per_cluster
    Integer( params[:per_cluster] || @user.try(:preference).try( :cluster_preview ) || 3 ) rescue 3
  end
  
end