# frozen-string-literal: true

########################################
# GEMFILE
########################################
run 'rm Gemfile'
file 'Gemfile', <<~GEMFILE_CONTENT
  # frozen-string-literal: true

  source 'https://rubygems.org'
  ruby '#{RUBY_VERSION}'

  gem 'devise'
  gem 'jbuilder', '~> 2.0'
  gem 'pg', '~> 0.21'
  gem 'puma'
  gem 'rails', '5.2.0'
  gem 'redis'

  # Needed for Active Storage
  # gem 'aws-sdk-s3', require: false
  # gem 'image_processing', '~> 1.2'

  gem 'autoprefixer-rails'
  gem 'bootstrap' # bootstrap 4
  gem 'font-awesome-sass'
  gem 'pundit'
  gem 'sass-rails'
  gem 'simple_form'
  gem 'uglifier'
  gem 'webpacker'

  group :development do
    gem 'bootsnap', require: false
    gem 'letter_opener'
    gem 'rubocop'
    gem 'rubocop-rspec'
    gem 'web-console', '>= 3.3.0'
    gem 'sqlite3'
  end

  group :test do
    gem 'database_cleaner'
    gem 'faker'
    gem 'rspec'
    gem 'simplecov'
    gem 'vcr'
    gem 'webmock'
  end

  group :development, :test do
    gem 'dotenv-rails'
    gem 'factory_bot_rails'
    gem 'listen', '~> 3.0.5'
    gem 'pry-byebug'
    gem 'pry-rails'
    gem 'spring', require: false
  end
GEMFILE_CONTENT

########################################
# Ruby version
########################################
run '.ruby-version'
file '.ruby-version', RUBY_VERSION

########################################
# Layout
########################################
file 'app/views/shared/_flashes.html.erb', <<~HTML
  <% if notice %>
    <div class="alert alert-info alert-dismissible" role="alert">
      <button type="button" class="close" data-dismiss="alert" aria-label="Close">
        <span aria-hidden="true">&times;</span>
      </button>

      <%= notice %>
    </div>
  <% end %>

  <% if alert %>
    <div class="alert alert-warning alert-dismissible" role="alert">
      <button type="button" class="close" data-dismiss="alert" aria-label="Close">
        <span aria-hidden="true">&times;</span>
      </button>

      <%= alert %>
    </div>
  <% end %>
HTML

file '.rspec', <<~RSPEC
  --color
  --format documentation
  --order random
  --require rails_helper
RSPEC

file 'spec/rails_helper.rb', <<~HELPER
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
HELPER

run 'touch .env'
run 'curl -L https://raw.githubusercontent.com/rikas/templates/master/.rubocop.yml > .rubocop.yml'

########################################
# Generators
########################################
generators = <<~RUBY
  config.generators do |generate|
    generate.assets false
    generate.helper false
    generate.test_framework :rspec, fixture: false
  end
RUBY

environment generators

########################################
# AFTER BUNDLE
########################################
after_bundle do
  rails_command 'db:drop db:create db:migrate'

  generate('simple_form:install', '--bootstrap')
  generate(:controller, 'pages', 'home', '--skip-routes', '--no-test-framework')

  route "root to: 'pages#home'"

  run 'rm .gitignore'
  file '.gitignore', <<~GITIGNORE
    .bundle
    log/*.log
    tmp/**/*
    tmp/*
    config/master.key
    !log/.keep
    !tmp/.keep
    *.swp
    .DS_Store
    public/assets
    public/packs
    public/packs-test
    node_modules
    yarn-error.log
    .byebug_history
    .env*
  GITIGNORE

  generate('devise:install')
  generate('devise', 'User')

  run 'rm app/controllers/application_controller.rb'
  file 'app/controllers/application_controller.rb', <<~RUBY
    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception

      before_action :authenticate_user!
    end
  RUBY

  rails_command 'db:migrate'
  generate('devise:views')

  run 'rm app/controllers/pages_controller.rb'
  file 'app/controllers/pages_controller.rb', <<~RUBY
    class PagesController < ApplicationController
      skip_before_action :authenticate_user!, only: [:home]

      def home
      end
    end
  RUBY

  environment "config.action_mailer.default_url_options = { host: 'localhost', port: '3000' }", env: 'development'
  environment "config.action_mailer.default_url_options = { host: 'TODO_PUT_YOUR_DOMAIN_HERE' }", env: 'production'

  # Webpacker / Yarn
  ########################################
  run 'rm app/javascript/packs/application.js'
  run 'yarn add jquery bootstrap'
  file 'app/javascript/packs/application.js', <<~JS
    import "bootstrap";
  JS

  inject_into_file 'config/webpack/environment.js', before: 'module.exports' do
    <<~JS
      // Bootstrap has a dependency over jQuery:
      const webpack = require('webpack');

      environment.plugins.prepend('Provide',
        new webpack.ProvidePlugin({
          $: 'jquery',
          jQuery: 'jquery'
        });
      );
    JS
  end

  git :init
  git add: '.'
  git commit: "-m 'Initial commit'"
end
