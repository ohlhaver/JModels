class GatewayTransaction < ActiveRecord::Base
  
  belongs_to :billing_record
  cattr_accessor :gateway
  
  attr_accessor :checksum
  attr_accessor :jurnalo_user_id
  
  before_save :convert_message_to_string
  
  # All params are present
  def ok?
    [ :remote_addr, :price, :subscription_id, :transaction_id, :checksum , :jurnalo_user_id ].inject( true ){ |s,x| s && !(send(x).blank?) }
  end
  
  def success?
    !self.new_record? && self.message == 'success'
  end
  
  protected
  
  def convert_message_to_string
    self.message = self.message.to_s if self.message
  end
  
end
