module Travis
  module Surveillance
    class Build
      ATTRIBUTES = [:author_name, :branch, :commit, :committed_at, :committer_name,
        :compare_url, :duration, :finished_at, :id, :message, :number, :project,
        :started_at, :status]
      attr_accessor *ATTRIBUTES

      def initialize(attributes = {})
        ATTRIBUTES.each do |attr|
          send("#{attr}=", attributes[attr.to_s]) if attributes[attr.to_s]
        end

        populate unless @number
      end

      def add_job(json)
        if job = job_for(json['id'])
          return job
        end

        job = Job.new(json.merge({'build' => self}))
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
        ATTRIBUTES.each do |attr|
          send("#{attr}=", details[attr.to_s]) if details[attr.to_s]
        end
      end
    end
  end
end
