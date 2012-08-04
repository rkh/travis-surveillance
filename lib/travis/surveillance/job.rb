module Travis
  module Surveillance
    class Job
      attr_accessor :id, :build, :number, :status

      def self.from_json(json, build)
        new({
          'id'       => json['id'],
          'build'    => build,
          'status'   => json['result']
        })
      end

      def initialize(attributes = {})
        @id       = attributes['id']
        @build    = attributes['build']
        @status   = attributes['status']
        populate
      end

      def failed?
        !status.nil? && !passed?
      end

      def passed?
        !status.nil? && status.zero?
      end

      def running?
        status.nil?
      end

      def state
        if running?
          'running'
        elsif passed?
          'passed'
        else
          'failed'
        end
      end

      private

      def get_details
        if Travis::Surveillance.mocking?
          JSON.parse(IO.read(File.dirname(__FILE__) + "/../../../spec/support/jobs/#{id}.json"))
        else
          JSON.parse(open("http://travis-ci.org/jobs/#{id}.json").read)
        end
      end

      def populate
        details = get_details
        @number = details['number']
      end
    end
  end
end
