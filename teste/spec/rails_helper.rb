# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

# Configure SimpleCov
require 'simplecov'
SimpleCov.start do
  load_profile 'test_frameworks'

  add_filter %r{^/config/}
  add_filter %r{^/db/}

  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Mailers', 'app/mailers'
  add_group 'Helpers', 'app/helpers'
  add_group 'Policies', 'app/policies'
  add_group 'Services', 'app/services'
  add_group 'Jobs', 'app/jobs'
  add_group 'Decorators', 'app/decorators'
  add_group 'Libraries', 'lib/'

  track_files '{app,lib}/**/*.rb'
end

require File.expand_path('../config/environment', __dir__)

# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'factory_bot'
require 'database_cleaner'
require 'vcr'
require 'webmock/rspec'

ActiveRecord::Migration.maintain_test_schema!

WebMock.disable_net_connect!

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.ignore_localhost = true
end

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Warden::Test::Helpers

  # Include FactoryBot so we can use 'create' instead of 'create'
  config.include FactoryBot::Syntax::Methods

  config.use_transactional_fixtures = false

  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!

  # Arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.before(:all) do
    DatabaseCleaner.strategy = :truncation, { except: %w[spatial_ref_sys] }
    DatabaseCleaner.start
  end

  config.after(:all) do
    DatabaseCleaner.clean
  end
end
