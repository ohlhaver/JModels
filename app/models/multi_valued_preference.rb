class MultiValuedPreference < ActiveRecord::Base
  
  unless defined?( PreferenceOptions )
    PreferenceOptions = { :search_languages => 1, :homepage_clusters => 2 }
  end
  
  belongs_to :owner, :polymorphic => true
  acts_as_list :scope => :owner
  
  validates_presence_of :value, :preference_id
  validates_uniqueness_of :value, :scope => [ :owner_type, :owner_id, :preference_id ]
  before_save :validates_presence_of_owner
  
  attr_accessor :status
  
  named_scope :owner, lambda{ |owner|
    { :conditions => { :owner_id => owner.id, :owner_type => owner.class.name } }
  }
  
  named_scope :owner_id_and_type, lambda{ |owner_id, owner_type|
    { :conditions => { :owner_id => owner_id, :owner_type => owner_type } }
  }
  
  named_scope :preference, lambda{ |preference_name| 
    { :conditions => { :preference_id => PreferenceOptions[ preference_name.try(:to_sym) ] },
      :order => 'position' }
  }
  
  unless method_defined?( :save_with_destroy )
    
    def save_with_destroy( perform_validation = true )
      return save_without_destroy( perform_validation ) if status.nil? || status.to_s == "1"
      return destroy if !new_record? && status.to_s == "0"
    end
    
    alias_method_chain :save, :destroy
    
  end
  
  class << self
    
    unless method_defined?( :initialize_with_find )
      
      def initialize_with_find( attributes = {} )
        record = new_without_find( attributes )
        if record.value && record.owner_id && record.owner_type && record.preference_id && !record.valid?
          record = find( :first, :conditions => { :value => record.value, :owner_id => record.owner_id, 
            :owner_type => record.owner_type, :preference_id => record.preference_id } )
          record.attributes = attributes
        end
        return record
      end
      
      alias_method_chain :initialize, :find
      
    end
    
  end
  
  def validates_presence_of_owner
    errors.add( :owner_id, :invalid ) unless owner( true )
  end
  
end