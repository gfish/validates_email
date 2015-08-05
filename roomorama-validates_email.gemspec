require File.expand_path("../lib/validates_email/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "roomorama-validates_email"
  s.version     = ValidatesEmail::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Donald Piret"]
  s.date        = ["2014-02-20"]
  s.email       = ["donald@roomorama.com"]
  s.homepage    = "http://github.com/roomorama/validates_email"
  s.summary     = "Rails plugin to validate email addresses"
  s.description = "Rails plugin to validate email addresses against RFC 2822 and RFC 3696"

  s.required_rubygems_version = ">= 1.3.6"

  s.files        = Dir["{lib}/**/*.rb", "MIT-LICENSE", "*.rdoc"]
  s.require_path = 'lib'

  s.add_dependency "activemodel", ">= 3.0.0"

  s.add_development_dependency 'activemodel', '~> 4.0'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rake'
end
