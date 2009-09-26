#!/usr/bin/env ruby

require 'rubygems'
require 'active_record'

Dir[File.join(File.dirname(__FILE__),'j_models/*.rb')].each do |m|
  require m
end
