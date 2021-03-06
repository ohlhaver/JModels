class MultiValuedPreference < ActiveRecord::Base
  
  serialize_with_options( :homepage_clusters ) do
    dasherize false
    map_include :cluster_group => :cluster_group_serialize
    except  :owner_id, :owner_type, :position, :tag, :preference_id, :value
  end
  
  serialize_with_options( :homepage_boxes ) do
    dasherize false
    map_include :element => :homepage_element_serialize
    except :owner_id, :owner_type, :position, :tag, :preference_id, :value
  end
  
  unless defined?( PreferenceOptions )
    # homepageboxes - TopStories, HomepageClusterGroups; TopAuthors; MyAuthors; MyTopics
    PreferenceOptions = { :search_languages => 1, :homepage_clusters => 2, :homepage_boxes => 3, :top_stories_cluster_group => 4, :wizards => 5 }
  end
  
  belongs_to :owner, :polymorphic => true, :touch => true
  belongs_to :cluster_group, :foreign_key => :value
  
  acts_as_list :scope => [ :owner, :preference_id, :tag ]
  
  #redefining scope condition # bugfix for the acts_as_list plugin
  def scope_condition
    self.class.send( :sanitize_sql_hash_for_conditions, { :owner_type => owner_type, :owner_id => owner_id, :preference_id => preference_id, :tag => tag } )
  end
  
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
      :order => 'position ASC' }
  }
  
  named_scope :tag, lambda { |tag|
    tag ? { :conditions => { :tag => tag } } : { }
  }
  
  unless method_defined?( :save_with_destroy )
    
    def save_with_destroy( perform_validation = true )
      return save_without_destroy( perform_validation ) if status.nil? || status.to_s == "1"
      return destroy if !new_record? && status.to_s == "0"
    end
    
    alias_method_chain :save, :destroy
    
  end
  
  class << self
    
    unless method_defined?( :new_with_find )
    
      def new_with_find( attributes = {} )
        record = new_without_find( attributes )
        if record.value && record.owner_id && record.owner_type && record.preference_id && !record.valid?
          record = find( :first, :conditions => { :value => record.value, :owner_id => record.owner_id, 
            :owner_type => record.owner_type, :preference_id => record.preference_id, :tag => record.tag } )
          record.attributes = attributes
        end
        return record
      end
      
      alias_method_chain :new, :find
      
    end
    
  end
  
  def cluster_group?
    preference_id == PreferenceOptions[ :homepage_clusters ]
  end
  
  def homepage_element?
    preference_id == PreferenceOptions[ :homepage_boxes ]
  end
  
  def homepage_element( reload = false )
    @element = nil if reload
    @element ||= Preference.for_select( :homepage_boxes ).select{ |x| x.last == self.value }
    @element.first.try( :first )
  end
  
  # def cluster_group
  #   preference_id == PreferenceOptions[ :homepage_clusters ] ? ClusterGroup.find( :first, :conditions => { :id => value } ) : nil 
  # end
  
  protected
  
  def cluster_group_serialize( options = {} )
    cluster_group.to_xml( options )
  end
  
  def homepage_element_serialize( options = {} )
    Preference.select_value_by_name_and_id( :homepage_boxes, self.value ).to_xml( options )
  end
  
  def validates_presence_of_owner
    errors.add( :owner_id, :invalid ) unless owner( true )
  end
  
end