require "json"
require "open-uri"

require "travis/surveillance/version"

module Travis
  module Surveillance
    module Logger
      def self.log(data, &block)
        STDOUT.puts data
        yield if block_given?
      end
    end

    # Public: Allows the user to specify a logger for the log messages that Travis::Surveillance
    # produces.
    #
    # logger = The object you want logs to be sent too
    #
    # Examples
    #
    #   Travis::Surveillance.instrument_with(STDOUT.method(:puts))
    #   # => #<Method: IO#puts>
    #
    # Returns the logger object
    def self.instrument_with(logger)
      @logger = logger
    end

    # Internal: Top level log method for use by Travis::Surveillance
    #
    # data = Logging data (typically a hash)
    # blk  = block to execute
    #
    # Returns the response from calling the logger with the arguments
    def self.log(data, &blk)
      logger.call({ 'travis-surveillance' => true }.merge(data), &blk)
    end

    # Public: The logging location
    #
    # Returns an Object
    def self.logger
      @logger || Travis::Surveillance::Logger.method(:log)
    end

    def self.mock!
      @mock = true
    end

    def self.mocking?
      @mock || false
    end

    class Spy
      attr_accessor :project

      def initialize(project)
        @project = project
      end

      def quick_reconnaissance
        if Travis::Surveillance.mocking?
          JSON.parse(IO.read(File.dirname(__FILE__) + "/../../spec/support/projects/#{project.gsub('/', '-')}.json"))
        else
          JSON.parse(open("http://travis-ci.org/#{project}.json").read)
        end
      end
    end
  end
end
