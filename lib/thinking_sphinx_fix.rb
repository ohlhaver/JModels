ThinkingSphinx::Search.class_eval do
  
  def client
    client = config.client
    
    index_options = one_class ?
      one_class.sphinx_indexes.first.local_options : {}
    
    [
      :max_matches, :group_by, :group_function, :group_clause,
      :group_distinct, :id_range, :cut_off, :retry_count, :retry_delay,
      :rank_mode, :max_query_time, :field_weights
    ].each do |key|
      # puts "key: #{key}"
      value = options[key] || index_options[key]
      # puts "value: #{value.inspect}"
      client.send("#{key}=", value) if value
    end
    client.select     = options.delete( :set_select ) || '*'
    client.limit      = per_page
    client.offset     = offset
    client.match_mode = match_mode
    client.filters    = filters
    client.sort_mode  = sort_mode
    client.sort_by    = sort_by
    client.group_by   = group_by if group_by
    client.group_function = group_function if group_function
    client.index_weights  = index_weights
    client.anchor     = anchor
    
    client
  end
  
end
