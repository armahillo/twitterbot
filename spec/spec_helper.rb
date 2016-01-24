require 'rubygems'
require 'stringio'
require 'multi_json'
require 'zlib'
require 'vcr'

# https://gist.github.com/mickey24/8131836
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)

def load_result_json(f)
  File.new("./spec/support/#{f}")
end

APP_ROOT = File.expand_path('../..', __FILE__)
Dir[File.join(APP_ROOT, 'spec/support/**/*.rb')].each {|f| require f}

serializer = Object.new
serializer.instance_eval do
  def file_extension
    "json"
  end
  def serialize(hash)
    JSON.pretty_generate(hash)
  end
  def deserialize(string)
    JSON.parse(string)
  end
end

VCR.configure do |config|
  config.preserve_exact_body_bytes do |http_message|
    http_message.body.encoding.name == 'ASCII-8BIT' || !http_message.body.valid_encoding?
  end
  config.before_record do |i|
    # Can't get it to decode the base64 data, but I think this is where it would happen?
    #i.response.body = Zlib::GzipReader.new(StringIO.new(i.response.body), encoding: 'ASCII-8BIT').read
    i.request.headers.delete("Authorization")
  end
  config.cassette_serializers[:basic_json] = serializer
  config.default_cassette_options = { :serialize_with => :basic_json }
  config.cassette_library_dir = "spec/fixtures/cassettes"
  config.hook_into :webmock
end

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  # These two settings work together to allow you to limit a spec run
  # to individual examples or groups you care about by tagging them with
  # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  # get run.
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # Enable only the newer, non-monkey-patching expect syntax.
    # For more details, see:
    #   - http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax
    expectations.syntax = :expect
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Enable only the newer, non-monkey-patching expect syntax.
    # For more details, see:
    #   - http://teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
    mocks.syntax = :expect

    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended.
    mocks.verify_partial_doubles = true
  end
  config.before(:each) do
  end
end
