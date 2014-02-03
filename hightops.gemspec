# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hightops/version'

Gem::Specification.new do |spec|
  spec.name          = 'hightops'
  spec.version       = Hightops::VERSION
  spec.authors       = ['Inbeom Hwang']
  spec.email         = ['inbeom@ultracaption.net']
  spec.summary       = %q{Implementation of AMQP communication protocol of Ultra.}
  spec.description   = %q{Using RabbitMQ and Sneakers, Hightops implements AMQP communication protocol of Ultra.}
  spec.homepage      = 'http://gitlab.ultracaption.net/hightops'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'sneakers', '~> 0.1.0.pre'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'multi_json'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rake'
end
