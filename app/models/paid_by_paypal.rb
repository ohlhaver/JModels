class PaidByPaypal < ActiveRecord::Base
  
  after_create :create_billing_record!
  validates_presence_of :transaction_id, :user_id 
  belongs_to :user
  
  # {"protection_eligibility"=>"Ineligible",
  #   "tax"=>"0.00",
  #   "payment_status"=>"Completed",
  #   "business"=>"seller_1274337491_biz@gmail.com",
  #   "payer_email"=>"buyer_1274339528_pre@gmail.com",
  #   "insurance_amount"=>"0.00",
  #   "receiver_id"=>"7WT4UHP87PDHG",
  #   "residence_country"=>"DE",
  #   "handling_amount"=>"0.00",
  #   "receiver_email"=>"seller_1274337491_biz@gmail.com",
  #   "discount"=>"0.0",
  #   "option_selection1"=>"3 months",
  #   "quantity"=>"1",
  #   "txn_type"=>"web_accept",
  #   "mc_currency"=>"EUR",
  #   "transaction_subject"=>"Jurnalo Power Plan",
  #   "charset"=>"windows-1252",
  #   "option_selection2"=>"49",
  #   "txn_id"=>"17W88504SB121713S",
  #   "item_name"=>"Jurnalo Power Plan",
  #   "payer_status"=>"verified",
  #   "option_name1"=>"Jurnalo Power Plan",
  #   "payment_date"=>"00:20:35 May 20, 2010 PDT",
  #   "mc_fee"=>"0.54",
  #   "option_name2"=>"Jurnalo User Id",
  #   "shipping_discount"=>"0.00",
  #   "shipping_method"=>"Default",
  #   "shipping"=>"0.00",
  #   "first_name"=>"Test",
  #   "payment_type"=>"instant",
  #   "btn_id"=>"1175513",
  #   "mc_gross"=>"9.95",
  #   "payer_id"=>"4HNDDU8K6RYZW",
  #   "last_name"=>"User",
  #   "item_number"=>"71231TT"}
  def self.create_by_pdt_response( pdt = {} )
    pay_record = new do |p|
     p.payment_status       = pdt['payment_status']
     p.payment_type         = pdt['payment_type']
     p.subscription_status  = pdt['option_selection3']
     p.user_id              = pdt['option_selection2']
     p.plan_name            = pdt['option_selection1']
     p.item_id              = pdt['item_number']
     p.amount               = (pdt['mc_gross'].to_f * 100_000).to_i
     p.name                 = pdt['first_name'] + ' ' + pdt['last_name']
     p.currency             = pdt['mc_currency']
     p.transaction_id       = pdt['txn_id']
     p.payer_id             = pdt['payer_id']
     p.payer_email          = pdt['payer_email']
    end
    pay_record.save
    return pay_record
  end
  
  def success?
    !new_record? && [ 'Completed', 'Created', 'Pending' ].include?( self.payment_status )
  end
  
  protected
  
  def create_billing_record!
    return unless [ 'Completed', 'Created', 'Pending' ].include?( self.payment_status )
    br = BillingRecord.create( :plan_id => self.item_id.to_i, :amount => self.amount, :user => self.user, :currency => self.currency, :checksum_salt => self.transaction_id )
    raise 'Billing Record could not be generated' if br.new_record?
    br.duration = self.plan_name.to_i.months
    br.event_time = self.starts_at if !self.starts_at.blank?
    br.payment_authorized! # First do the authorization
    br.payment_confirmed! # Upgrades the User
    self.update_attribute( :starts_at, br.event_time )
    self.update_attribute( :ends_at, br.event_time + br.duration )
  end
  
end
