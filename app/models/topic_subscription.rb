class TopicSubscription < ActiveRecord::Base
  
  belongs_to :owner, :polymorphic => true
  
  validates_uniqueness_of :name, :scope => [ :owner_type, :owner_id ]
  validate :validates_presence_of_search_keywords
  
  def time_range
    start = ( time_span || owner.preference.default_time_span ).seconds.from_now
    start..Time.now
  end
  
  def stories( page = '1')
    Story.search( *to_sphinx( page ) )
  end
  
  def to_sphinx( page = '1' )
    options = { 
      :page => page || '1', 
      :per_page => owner.preference.per_page, 
      :match_mode => :extended
    }
    options.merge!( Story::Sort[ sort_criteria || owner.preference.default_sort_criteria ] )
    options[:with].merge( :author_id => author_id )     if author_id
    options[:with].merge( :category_id => category_id ) if category_id
    options[:with].merge( :source_id => source_id )     if source_id
    if region_id
      source_ids = Region.find( :first, :conditions => { :id => region_id } , :include => :sources ).try(:source_ids)
      options[:with].merge( :source_id => source_ids ) if source_ids
    end
    options[:with].merge( :created_at => time_range )
    [ search_terms, options ]
  end
  
  protected
  
  def search_any_terms
    Array( search_any.try( :split, /(\s+|\,)/ ).try( :select ){ |x| x =~ /\w+/ }.try(:join, ' | ') )
  end
  
  def search_all_terms
    search_all.try( :split, /(\s+|\,)/ ).try( :select ){ |x| x =~ /\w+/ } || []
  end
  
  def search_exact_phrase_terms
    search_exact_phrase.try( :split, /\,\s*/ ).try( :select ){ |x| x =~ /\w+/ }.try( :collect ){ |x| x.dump } || []
  end
  
  def search_except_terms
    search_except.try( :split, /(\s+|\,)/ ).try( :select ){ |x| x =~ /\w+/ }.try( :collect ){ |x| "!#{x}" } || []
  end
  
  def search_terms
    ( search_any_terms + search_all_terms + search_exact_phrase_terms + search_except_terms ).select{ |x| !x.blank? }.collect{ |x| "( #{x} )" }.join(' & ')
  end
  
  
  def validates_presence_of_search_keywords
    if search_all.blank? && search_any.blank? && search_exact.blank?
      errors.add( :search_keyword, :required )
    end
  end
  
end