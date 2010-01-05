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
    self.options[:without].merge!( :author_ids => 0 ) if self.mode == :author
    self.options[:without].merge!( :source_id => 0 ) if self.mode == :source
    add_sort_criteria 
    add_time_span
    add_blog_pref
    add_video_pref
    add_opinion_pref
    add_filter_author_ids
    add_filter( :category_id )
    add_filter_region_id
    add_filter( :source_id )
    add_subscription_type
    add_language_ids
  end
  
  def populate_string
    @string = case( mode ) when :advance, :topic : populate_advance_search_string
    else ( @parser.parse( params[:q] || '' ).try(:root).try(:eval) || [] ).join(' ') end
  end
  
  def results
    Story.search( string, options.merge( :page => page, :per_page => per_page, :include => :authors ) )
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
  
  protected
  
  def page
    Integer( params[:page] || 1 ) rescue 1
  end
  
  def per_page
    @per_page ||= user.try( :preference ).try( :per_page ) || 10
    Integer( params[:per_page] || @per_page ) rescue 10
  end
  
  #public private paid
  def add_subscription_type
    attr_value = column_eval( :subscription_type ) || user.try( :preference ).try( :subscription_type )
    case ( attr_value ) when '2', 2
      options[:with].merge!( :subscription_type => [ 1, 2 ] )
    when '3', 3
      options[:with].merge!( :subscription_type => [ 1 ] )
    end
  end
  
  def add_filter( attr_name )
    attr_value = Array( column_eval( "#{attr_name}s".to_sym ) || column_eval( attr_name ) )
    attr_value.collect!{ |x| x.to_i }
    options[:with].merge!( attr_name => attr_value ) unless attr_value.blank?
  end
  
  def add_filter_author_ids
    attr_value = Array( column_eval( :author_ids ) || column_eval( :author_id ) )
    attr_value.collect!{ |x| x.to_i }
    options[:with].merge!( :author_ids => attr_value ) unless attr_value.blank?
  end
  
  def add_filter_region_id
    region_id = column_eval( :region_id )
    region_id = nil if region_id == -1 
    if region_id 
      source_ids = Region.find( :first, :conditions => { :id => region_id } , :include => :sources ).try(:source_ids)
      options[:with].merge!( :source_id => source_ids ) if source_ids
    end
  end
  
  def add_sort_criteria
    sort_criteria = column_eval( :sort_criteria ) ||  user.try( :preference ).try( :default_sort_criteria ) || Preference.select_value_by_name_and_code( :sort_criteria, :relevance )[ :id ]
    case( sort_criteria ) when "2", 2
      options.merge!(  :sort_mode => :desc, :order => :created_at )
    when "3", 3
      options.merge!(  :sort_mode => :desc, :order => :created_at, :group_by => 'group_id', :group_function => :attr )
      options[:without].merge!( :group_id => 0 )
    when "1", 1
      options.merge!( :group_by => 'group_id', :group_function => :attr, :sort_mode => :expr, :order => "@weight * quality_rating * (100/POW( 1 + (NOW() - created_at), 0.33 ) )" )
      options[:without].merge!( :group_id => 0 )
    else
      options.merge!( :sort_mode => :expr, :order => "@weight * quality_rating * (100/POW( 1 + (NOW() - created_at), 0.33 ) )" )
    end
  end
  
  def add_time_span
    return if column_eval( :time_span ) == 'skip'
    timespan = Preference.select_value_by_name_and_code( :time_span, column_eval( :time_span ).try( :to_sym ) ) || user.try( :preference ).try( :default_time_span ) || Preference.select_value_by_name_and_code( :time_span, :last_month )[:id ]
    options[:with].merge!( :created_at => ( (timespan.seconds.ago)..(Time.now) ) )
  end
  
  def add_language_ids
    language_ids = user.try( :preference ).try( :search_language_ids ) || Preference.default_language_id_for_region_id( column_eval( :region_id ) || -1 )
    options[:with].merge!( :language_id => language_ids )
  end
  
  def set_vob_pref( attr_name, attr_value )
    case attr_value  when "0", 0
      self.options[:with].merge!( attr_name => 0 )
    when "1", 1
      self.options[:order].try( :<<, "*IF( #{attr_name} = 0, 2, 0.5)" )
    when "3", 3
      self.options[:order].try( :<<, "*IF( #{attr_name} = 1, 2, 0.5)" )
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
    stmt = ( @parser.parse( column_eval( :search_any ).to_s ).try( :root ).try( :eval ) || [] ).join(' | ')
    stmt = "( #{stmt} )" unless stmt.blank?
    Array( stmt.blank? ? nil : stmt )
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
    ( search_any_terms + search_all_terms + search_exact_phrase_terms + search_except_terms ).join(' & ')
  end
  
  def column_eval( column_name )
    value = params[ column_name ]
    value.blank? ? nil : value
  end
  
end