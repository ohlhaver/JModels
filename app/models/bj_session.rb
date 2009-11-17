class BjSession < ActiveRecord::Base
  
  module Jobs
    CandidateGeneration = 1
    DuplicateMarker     = 2
    GroupGeneration     = 3
    ClusterGeneration   = 4
  end
  
  def self.last( job_id )
    created_at = maximum( :created_at, :conditions => { :job_id => job_id } )
    find( :first, :conditions => { :job_id => job_id, :created_at => created_at } )
  end
  
end