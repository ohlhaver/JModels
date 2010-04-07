$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'account_restriction'
ActiveRecord::Base.class_eval { include ActiveRecord::UserAccountRestriction}