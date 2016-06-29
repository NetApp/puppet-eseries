require 'rspec'
require 'rspec-puppet'
require 'rspec/expectations'
require 'rspec/autorun'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'puppet/parameter/boolean'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |config|
  config.module_path = File.join(fixture_path, 'modules')
  config.manifest_dir = File.join(fixture_path, 'manifests')
  config.mock_framework = :rspec
end

all_app_files = Dir.glob('{app,lib}/**/*.rb')
all_app_files.each { |rb| require rb }


# don't want to do real calls to API during tests
Excon.defaults[:mock] = true
