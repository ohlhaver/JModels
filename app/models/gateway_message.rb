class GatewayMessage < ActiveRecord::Base
  
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
  
end
