class BjSession < ActiveRecord::Base
  
  module Jobs
    
    unless defined?(BjSession::Jobs::CandidateGeneration)
      CandidateGeneration     = 1
      DuplicateMarker         = 2 # Across Source
      DuplicateDeletion       = 5 # Within Source
      GroupGeneration         = 3
      QualityRatingGeneration = 4
      TopAuthorGeneration     = 6 
      EmailNotification       = 7
    end
    
  end
  
  named_scope :find_by_job_id, lambda{ |job_id| { :conditions => { :job_id => job_id } } }
  named_scope :recent, { :order => 'created_at DESC' }
  named_scope :not_running, :conditions => { :running => false }
  named_scope :running, :conditions => { :running => true }
  
  def self.current( job_id )
    find_by_job_id( job_id ).not_running.recent.first
  end
  
end