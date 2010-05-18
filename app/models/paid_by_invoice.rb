class PaidByInvoice < ActiveRecord::Base
  
  # Price is in millicents ( Legacy from CnB )
  cattr_accessor :plans
  
  set_primary_key :user_id
  
  belongs_to :user
  
  validates_presence_of :account_name
  validates_presence_of :address
  validates_presence_of :city
  validates_presence_of :country
  validates_presence_of :zip
  
  after_create :create_billing_record!
  
  def deactivate!
    self.update_attibute( :active, false )
  end
  
  def create_next_billing_record!
    return unless self.active?
    br = BillingRecord.create( :plan_id => plan_id, :amount => self.price, :user => self.user, :currency => self.currency )
    br.event_time = next_bill_date if next_bill_date > 1.month.ago
    br.generate_invoice!
    self.update_attribute( :next_bill_date, br.event_time + 1.month )
  end
  
  def self.each_due(&block)
    current_time = Time.now.utc - 12.hours
    find_each( :conditions => [ 'next_bill_date < ? AND active = ?', current_time, true ], &block )
  end
  
  protected
  
  def create_billing_record!
    br = BillingRecord.create( :plan_id => plan_id, :amount => self.price, :user => self.user, :currency => self.currency )
    br.generate_invoice!
    self.update_attribute( :next_bill_date, br.event_time + 1.month )
  end
  
end