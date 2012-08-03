module Travis
  module Surveillance
    class Build
      attr_accessor :id, :number, :project_id, :status

      def self.from_json(json, project_id = nil)
        new({
          'id'         => json['id'],
          'number'     => json['number'],
          'project_id' => project_id,
          'status'     => json['status']
        })
      end

      def initialize(attributes = {})
        @id         = attributes['id']
        @number     = attributes['number']
        @project_id = attributes['project_id']
        @status     = attributes['status']
      end

      def add_job(json)
        if job = job_for(json['id'])
          return job
        end

        job = Job.from_json(json, @id)
        jobs << job
        job
      end

      def building?
        status.nil?
      end

      def failed?
        !status.nil? && !passed?
      end

      def job_for(id)
        jobs.find { |j| j.id == id }
      end

      def passed?
        !status.nil? && status.zero?
      end

      def jobs
        @jobs ||= []
      end
    end
  end
end
