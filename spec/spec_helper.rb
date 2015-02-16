require 'rspec'
require 'rspec/expectations'
require 'rspec/autorun'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'puppet/parameter/boolean'

RSpec.configure do |config|
  config.mock_framework = :rspec
end

all_app_files = Dir.glob('{app,lib}/**/*.rb')
all_app_files.each { |rb| require rb }

# don't want to do real calls to API during tests
Excon.defaults[:mock] = true
