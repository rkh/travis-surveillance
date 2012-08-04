module Travis
  module Surveillance
    class Build
      attr_accessor :id, :number, :project, :status

      def self.from_json(json, project = nil)
        new({
          'id'         => json['id'],
          'number'     => json['number'],
          'project' => project,
          'status'     => json['status']
        })
      end

      def initialize(attributes = {})
        @id         = attributes['id']
        @number     = attributes['number']
        @project    = attributes['project']
        @status     = attributes['status']
        populate unless @number
      end

      def add_job(json)
        if job = job_for(json['id'])
          return job
        end

        job = Job.from_json(json, self)
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

      def jobs
        @jobs ||= []
      end

      def passed?
        !status.nil? && status.zero?
      end

      def state
        if building?
          'building'
        elsif passed?
          'passed'
        else
          'failed'
        end
      end

      private

      def get_details
        if Travis::Surveillance.mocking?
          JSON.parse(IO.read(File.dirname(__FILE__) + "/../../../spec/support/builds/#{project.slug.gsub('/', '-')}-#{id}.json"))
        else
          JSON.parse(open("http://travis-ci.org/#{project.slug}/builds/#{id}.json").read)
        end
      end

      def populate
        details = get_details
        @id          = details['id']
        @number      = details['number']
        @status      = details['status']
      end
    end
  end
end
