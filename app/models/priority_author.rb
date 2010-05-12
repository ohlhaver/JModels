class PriorityAuthor < ActiveRecord::Base
  
  set_primary_key :author_id
  
  belongs_to :author
  
  def self.add_to_list( author )
    author_id = author.is_a?( Author ) ? author.id : author
    record = self.find( author_id ) rescue nil
    record ||= self.new( :checked => false ){ |r| r.id = author_id }
    if record.new_record? || ( record.checked? && record.last_checked_at < 30.days.ago )
      record.checked = false
      record.save
    end
    return record
  end
  
  def self.checked( author )
    author_id = author.is_a?( Author ) ? author.id : author
    record = self.find( author_id ) rescue nil
    return unless record
    record.update_attributes( :checked => true, :last_checked_at => Time.now.utc ) unless record.checked?
  end
  
end