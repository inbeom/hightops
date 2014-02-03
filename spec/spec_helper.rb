require 'rubygems'
require 'bundler/setup'

$:.unshift(File.join(File.dirname(__FILE__), '../lib'))
require 'hightops'

Dir['./lib/hightops/**/*.rb'].each { |f| require f }
