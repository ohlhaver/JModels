class GatewayMessage < ActiveRecord::Base
  
  after_create :process_if_recurring
  
  def self.store( message )
    h = Hash.from_xml( message ) rescue {}
    attributes = { :response => message }
    begin 
      attributes[:event_id] = h["EVENT_DATA"]["GLOBAL"]["event_id"]
      attributes[:event_type]   = (h["EVENT_DATA"].keys - ["GLOBAL"]).first
      case( attributes[:event_type] ) when "SUBSCRIPTION"
        attributes[:action] = h["EVENT_DATA"]["SUBSCRIPTION"]["subscribe_data"]["action"]
        attributes[:subscriber_id] = h["EVENT_DATA"]["SUBSCRIPTION"]["subscribe_data"]["action"]["subscribe_id"]
      when "EVENT_SWITCH"
        attributes[:action] = h["EVENT_DATA"]["EVENT_SWITCH"]["action"]
      end
    rescue StandardError
    end
    self.create( attributes )
  end
  
  def self.consume_recurring
    records = find( :all, :conditions => { :action => :recurring, :parsed => nil } )
    count = 0
    records.each{ |r| 
      count += 1 if r.send( :process_if_recurring ) 
    }
    return count
  end
  
  protected
  
  def process_if_recurring
    return unless action == "recurring"
    hash = Hash.from_xml( self.response ) rescue {}
    event_time = hash["EVENT_DATA"]["GLOBAL"]["datetime"].to_time
    j_user_id = hash["EVENT_DATA"]["SUBSCRIPTION"]["subscribe_data"]["external_id"]
    user = User.find( :first, :conditions => { :id => j_user_id } )
    return unless user
    url = hash["EVENT_DATA"]["SUBSCRIPTION"]["subscribe_data"]["click_url"]
    bdr_id = url.match(/j_bdr_id=(\d+)&/).to_a[1].to_i
    bdr = user.billing_records.find( :first, :conditions => { :id => bdr_id } )
    return unless bdr
    bdr.event_time = event_time
    bdr.subscription_renewed!
    self.update_attribute( :parsed, true )
  end
  
end
