# frozen_string_literal: true

# needs to be at the top of the file
require "simplecov"

if ENV["COVERAGE"]
  SimpleCov.start do
    add_filter "/spec/"
    add_filter "/vendor/"
    # Add any other paths you want to exclude

    add_group "Lib", "lib"

    track_files "lib/**/*.rb"
  end
end

# end simplecov

require "chromedriver/binary"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
