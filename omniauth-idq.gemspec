# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "omniauth-idq/version"

# p OmniAuth::Idq::VERSION
Gem::Specification.new do |s|
  s.name        = "omniauth-idq"
  s.version     = OmniAuth::Idq::VERSION
  s.authors     = ["inBay Technologies Inc."]
  s.email       = ["support@idquanta.com"]
  s.homepage    = "https://github.com/inbaytech/omniauth-idq"
  s.summary     = %q{OmniAuth strategy for idQ}
  s.description = %q{OmniAuth strategy for idQ}

  s.rubyforge_project = "omniauth-idq"

  s.files = Dir[
              'lib/**/*',
              'spec/**/*',
              '*.gemspec',
              '*.md',
              'Rakefile',
              'Gemfile',
              'LICENSE.md',
              'README.md'
            ]
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'omniauth-oauth2', '~> 1.4.0'
  s.add_development_dependency 'rspec', '~> 2.7'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'webmock'
end
