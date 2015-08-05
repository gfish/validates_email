require 'active_model'
require 'rspec'

require 'validates_email'
require 'person'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
