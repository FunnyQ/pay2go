# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pay2go_invoice/version'

Gem::Specification.new do |spec|
  spec.name          = 'pay2go_invoice_client'
  spec.version       = Pay2goInvoice::VERSION
  spec.authors       = ['FunnyQ']
  spec.email         = ['funnyq@gmail.com']

  spec.summary       = 'API client for pay2go invoice platform.'
  spec.description   = 'API client for pay2go invoice platform.'
  spec.homepage      = 'https://github.com/CalvertYang/pay2go'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'json'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.8'
  spec.add_development_dependency 'minitest-reporters', '~> 1.1'
  spec.add_development_dependency 'sinatra'
end
