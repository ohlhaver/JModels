class AccountStatusPoint < ActiveRecord::Base
  
  belongs_to :user, :touch => true
  
  def plan_id_variant
    read_attribute(:plan_id) 
  end
  
  def plan_id
    plan_id = read_attribute(:plan_id) 
    plan_id && plan_id > 0 ? 1 : plan_id
  end
  
end
