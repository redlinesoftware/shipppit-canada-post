# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'canada_post/version'

Gem::Specification.new do |spec|
  spec.name          = "canada-post-api"
  spec.version       = CanadaPost::VERSION
  spec.authors       = ["Olivier"]
  spec.email         = ["olivier@yafoy.com"]
  spec.summary       = %q{Canada Post API}
  spec.description   = %q{Ruby wrapper for the Canada Post API V3}
  spec.homepage      = "https://github.com/shipppit/shipppit-canada-post"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty", "~> 0.13.7"
  spec.add_dependency "nokogiri", '~> 1.6', '>= 1.6.7.1'
  spec.add_dependency "activesupport", "~> 4.2"

  spec.add_development_dependency "bundler",  "~> 1.7"
  spec.add_development_dependency "rake",     "~> 10.0"

  # FOR TESTING ONLY
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "webmock", "~> 1.22"
  spec.add_development_dependency "vcr", "~> 3.0"
end
