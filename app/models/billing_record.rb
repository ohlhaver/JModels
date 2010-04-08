class BillingRecord < ActiveRecord::Base
  
  attr_accessor :premium_link
  
  belongs_to :user
  has_many  :gateway_transactions
  
  validates_presence_of   :user_id
  validates_uniqueness_of :user_id, :if => Proc.new{ |br| self.exists?( :user_id => br.user_id, :state => 'paid' ) }, :message => :already_subscribed
  
  before_create :populate_checksum_salt
  
  acts_as_state_machine :initial => :pending
  
  # Payment State
  state :pending                                      # Payment Pending
  state :authorized                                   # 1st HandShake Success
  state :paid, :enter => :upgrade_user_status         # 2nd Handshake Success
  state :verification_pending                         # Timeout Error
  state :failed                                       # Error When Making Payment
  state :renewed, :after => :payment_confirmed!       # Subscripition Renewed
  state :cancelled, :enter => :downgrade_user_status  # Subscription Cancelled
  state :terminated, :enter => :downgrade_user_status # Subscription Terminated

  event :payment_authorized do
    transitions :from => :pending,
                :to   => :authorized
  end
  
  event :payment_verify do
    transitions :from => :authorized,
                :to => :verification_pending
  end

  event :payment_confirmed do
    transitions :from => :verification_pending,
                :to => :paid
    transitions :from => :authorized,
                :to   => :paid
    transitions :from => :renewed,
                :to   => :paid
  end

  event :payment_error do
    transitions :from => :pending,
                :to   => :failed
    transitions :from => :authorized,
                :to   => :failed
    transitions :from => :verification_pending,
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
                :to   => :renewed
    transitions :from => :cancelled,
                :to   => :renewed
  end
  
  event :subscription_terminated do
    transitions :from => :paid,
                :to => :terminated
    transitions :from => :cancelled,
                :to => :terminated
    transitions :from => :terminated,
                :to => :terminated
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
    user.account_status_points.create( :plan_id => plan_id, 
      :billing_record_id => self.id, 
      :starts_at => Time.now.utc, 
      :ends_at => Time.now.utc + 30.days 
    )
    # puts "upgrade callback called"
  end
  
  def downgrade_user_status
    puts "downgrade callback called"
  end
  
  protected
  
  def populate_checksum_salt
    self.checksum_salt = Authlogic::Random.friendly_token
  end
  
end
