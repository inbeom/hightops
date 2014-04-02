require 'rubygems'
require 'bundler/setup'

$:.unshift(File.join(File.dirname(__FILE__), '../lib'))
require 'hightops'

Dir['./spec/support/**/*.rb'].each { |f| require f }
