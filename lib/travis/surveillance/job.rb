module Travis
  module Surveillance
    class Job
      attr_accessor :id, :build_id, :status

      def self.from_json(json, build_id)
        new({
          'id'       => json['id'],
          'build_id' => build_id,
          'status'   => json['result']
        })
      end

      def initialize(attributes = {})
        @id       = attributes['id']
        @build_id = attributes['build_id']
        @status   = attributes['status']
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
    end
  end
end
