class Category < ActiveRecord::Base
  
  validates_presence_of   :id, :name, :code
  validates_uniqueness_of :code
  
  def self.top_category_id( category_ids )
    return nil if category_ids.blank?
    groups = category_ids.group_by{ |x| x }
    groups.each_pair{ |k,v| groups[k] = v.size }
    unique_category_ids = groups.keys.sort_by{ |x| -groups[x] }
    top_count = groups[ unique_category_ids.first ]
    top_category_ids = unique_category_ids.select{ |x| groups[x] == top_count }
    return top_category_ids.first if top_category_ids.size < 2
    return prefered_category_id( top_category_ids )
  end
  
  def self.prefered_category_id( category_ids )
    category_ids.sort!
    category_ids.first
  end
  
end
