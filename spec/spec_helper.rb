# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration

require 'simplecov'

if ENV['TRAVIS']
  require 'codeclimate-test-reporter'
  require 'coveralls'

  # code climate
  CodeClimate::TestReporter.configure do |config|
    config.logger.level = Logger::WARN
  end
  CodeClimate::TestReporter.start

  # coveralls
  Coveralls.wear!

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      Coveralls::SimpleCov::Formatter,
      CodeClimate::TestReporter::Formatter
  ]

else
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter
  ]
end

# start code coverage
SimpleCov.start

require 'zonebie'
require 'baw-workers'
require 'fakeredis'
require 'active_support/core_ext'

# include shared_context
Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each {|file| require file }

# include rake tasks
require 'rake'
Dir[File.join(File.dirname(__FILE__), '..', 'lib', 'tasks', '*.rb')].each { |file| require file }

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  #config.profile_examples = 20

  Zonebie.set_random_timezone

  # redirect puts into a text file
  original_stderr = STDERR.clone
  original_stdout = STDOUT.clone

  # provide access to tmp dir and stdout and stderr files
  config.add_setting :tmp_dir
  config.tmp_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'tmp'))

  config.add_setting :default_settings_path
  config.default_settings_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'settings.default.yml'))

  config.add_setting :program_stdout
  config.program_stdout = File.join(config.tmp_dir, 'program_stdout.log')

  config.add_setting :program_stderr
  config.program_stderr = File.join(config.tmp_dir, 'program_stderr.log')

  config.before(:all) do
    FileUtils.mkdir_p(config.tmp_dir)
  end

  config.before(:each) do
    # Redirect stderr and stdout
    STDERR.reopen(File.open(config.program_stderr, 'w+'))
    STDERR.sync = true
    STDOUT.reopen(File.open(config.program_stdout, 'w+'))
    STDOUT.sync = true
  end

  config.after(:each) do
    # restore stderr and stdout
    STDERR.reopen(original_stderr)
    STDOUT.reopen(original_stdout)

    # clear stdout and stderr files
    FileUtils.rm config.program_stderr if File.exists? config.program_stderr
    FileUtils.rm config.program_stdout if File.exists? config.program_stdout
  end

  # setting the source file here means the rake task cannot change it
  BawWorkers::Settings.set_source(config.default_settings_path)
  BawWorkers::Settings.set_namespace('settings')

  require 'action_mailer'

  unless defined? Settings
    class Settings < BawWorkers::Settings
      source BawWorkers::Settings.source
      namespace 'settings'
      BawWorkers::Settings.set_mailer_config
      ActionMailer::Base.delivery_method = :test

      Resque.redis = Redis.new
      Resque.redis.namespace = Settings.resque.namespace
    end
  end

end
