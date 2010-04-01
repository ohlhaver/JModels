class GatewayTransaction < ActiveRecord::Base
  
  belongs_to :billing_record
  
  attr_accessor :checksum
  attr_accessor :jurnalo_user_id
  
  # All params are present
  def ok?
    ( self.class.column_names.collect(&:to_sym) + [ :checksum , :jurnalo_user_id ] - [ :id, :message, :created_at, :updated_at ] ).inject( true ){ |s,x| s && !(send(x).blank?) }
  end
  
end
