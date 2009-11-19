class BjSession < ActiveRecord::Base
  
  module Jobs
    unless defined?(CandidateGeneration)
      CandidateGeneration = 1
      DuplicateMarker     = 2
      GroupGeneration     = 3
      QualityRating       = 4
    end
  end
  
  def self.last( job_id )
    find( :first, :conditions => [ 'job_id = ? AND duration IS NOT NULL', job_id ], :group => 'job_id', :having => 'MAX( created_at )', :order => 'id DESC' )
  end
  
end