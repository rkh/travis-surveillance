# encoding: utf-8

require "clamp"
require "scrolls"
require "travis/surveillance"

module Travis
  module Surveillance
    module CLI
      class Logger
        def self.log(data, &block)
          Scrolls.log(data, &block)
        end
      end

      def self.run(*a)
        MainCommand.run(*a)
      end

      class AbstractCommand < Clamp::Command
        option ["-p", "--project"], "PROJECT", "projeter à regarder", :required => true

        option "--version", :flag, "show version" do
          puts "travis-surveillance #{Travis::Surveillance::VERSION}"
          exit 0
        end
      end

      class MainCommand < AbstractCommand
        def execute
          surveyor = Travis::Surveillance::Surveyor.new(Travis::Surveillance::Project.new(project))
          surveyor.survey
        end
      end
    end
  end
end

Travis::Surveillance.instrument_with(Travis::Surveillance::CLI::Logger.method(:log))
