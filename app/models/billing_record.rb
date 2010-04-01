class BillingRecord < ActiveRecord::Base
  
  attr_accessor :premium_record
  
  belongs_to :user
  has_many  :gateway_transactions
  
  validates_presence_of   :user_id
  validates_uniqueness_of :user_id, :if => Proc.new{ |br| self.class.exists?( :user_id => br.user_id, :status => :paid ) }, :message => :already_subscribed
  
  before_create :populate_checksum_salt
  
  acts_as_state_machine :initial => :pending do
  
    # Payment State
    state :pending        # Payment Pending
    state :authorized     # 1st HandShake Success
    state :paid           # 2nd Handshake Success
    state :failed         # Error When Making Payment
    state :cancelled      # Subscription Cancelled
    state :terminated     # Subscription Terminated
    
    after_transition :to => :paid,      :do => :upgrade_user_status
    after_transition :to => :cancelled, :do => :downgrade_user_status
  
    event :payment_authorized do
      transitions :from => :pending,
                  :to   => :authorized
    end
  
    event :payment_confirmed do
      transitions :from => :authorized,
                  :to   => :paid
    end
  
    event :payment_error do
      transitions :from => :pending,
                  :to   => :failed
      transitions :from => :authorized,
                  :to   => :failed
    end
  
    event :subscription_cancelled do
      transitions :from => :paid,
                  :to   => :cancelled
      transitions :from => :cancelled,
                  :to   => :cancelled
    end
    
    event :subscription_renewed do
      transitions :from => :paid,
                  :to   => :paid
      transitions :from => :cancelled,
                  :to   => :paid
    end
    
    event :subscription_upgraded do
      transitions :from => :paid,
                  :to   => :paid
      transitions :from => :cancelled,
                  :to   => :paid
    end
    
    event :subscription_terminated do
      transitions :from => :paid,
                  :to => :terminated
      transitions :from => :cancelled,
                  :to => :terminated
      transitions :from => :terminated,
                  :to => :terminated
    end
    
  end
  
  # OrderId Checksum
  def checksum
    self.id && self.checksum_salt ? Digest::MD5.hexdigest( "#{checksum_salt}#{id}" ) : nil
  end
  
  def upgrade_user_status
    # Create an Account Record
    # Refers the Order Id
    # Expiry Date, Start Date
    # Account Status: 0,1,2,3,4,5 Basic/Power/Business
  end
  
  def downgrade_user_status
  end
  
  protected
  
  def populate_checksum_salt
    self.checksum_salt = Authlogic::Random.friendly_token
  end
  
end
