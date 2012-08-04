module Travis
  module Surveillance
    class Job
      ATTRIBUTES = [:build, :finished_at, :id, :number, :started_at, :status]
      attr_accessor *ATTRIBUTES

      def initialize(attributes = {})
        ATTRIBUTES.each do |attr|
          send("#{attr}=", attributes[attr.to_s]) if attributes[attr.to_s]
        end

        populate
      end

      def duration
        if started_at && finished_at
          finished_at - started_at
        elsif started_at
          Time.now - started_at
        else
          0
        end
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
        ATTRIBUTES.each do |attr|
          send("#{attr}=", details[attr.to_s]) if details[attr.to_s]
        end
      end
    end
  end
end
