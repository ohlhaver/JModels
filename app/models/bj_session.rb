class BjSession < ActiveRecord::Base
  
  module Jobs
    
    unless defined?(BjSession::Jobs::CandidateGeneration)
      CandidateGeneration = 1
      DuplicateMarker     = 2
      GroupGeneration     = 3
      QualityRating       = 4
    end
    
  end
  
  named_scope :find_by_job_id, lambda{ |job_id| { :conditions => { :job_id => job_id } } }
  named_scope :recent, { :group => 'job_id', :having => 'MAX( created_at )' }
  named_scope :not_running, :conditions => { :running => false }
  named_scope :running, :conditions => { :running => true }
  
  def self.current( job_id )
    find_by_job_id( job_id ).not_running.recent.first
  end
  
end