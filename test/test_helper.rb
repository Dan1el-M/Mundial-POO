ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module Rails
  module LineFiltering
    # Ruby 4 ships with a newer Minitest signature for `run`.
    # Forwarding all arguments keeps Rails 7.1 test execution working here.
    def run(*args, &block)
      super(*args, &block)
    end
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors, with: :threads)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
