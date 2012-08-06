module Travis
  module Surveillance
    class Build
      class Config
        ATTRIBUTES = [:language]
        attr_accessor *ATTRIBUTES

        def initialize(attrs = {})
          self.attributes = attrs
        end

        def attributes=(attrs = {})
          attrs.each do |key, value|
            send("#{key}=", value) if ATTRIBUTES.include?(key.to_sym)
          end
        end
      end
      ATTRIBUTES = [:author_name, :branch, :commit, :committed_at, :committer_name,
        :compare_url, :duration, :finished_at, :id, :message, :number, :project,
        :result, :started_at]
      attr_accessor *ATTRIBUTES

      def initialize(attrs = {})
        self.attributes = attrs

        populate
      end

      def add_job(json)
        if job = job_for(json['id'])
          return job
        end

        job = Job.new(json.merge({'build' => self}))
        jobs << job
        jobs.sort_by! { |j| j.id }
        job
      end

      def attributes=(attrs = {})
        attrs.each do |key, value|
          next if value.nil?
          if key == 'config'
            config.attributes = value
          elsif key == 'matrix'
            value.each do |job|
              add_job(job)
            end
          else
            send("#{key}=", (key[/_at$/] ? Time.parse(value) : value)) if ATTRIBUTES.include?(key.to_sym)
          end
        end
      end

      def building?
        result.nil?
      end

      def config
        @config ||= Config.new
      end

      def duration
        if started_at && finished_at
          finished_at - started_at
        elsif started_at
          Time.now - started_at
        else
          nil
        end
      end

      def failed?
        !result.nil? && !passed?
      end

      def job_for(id)
        jobs.find { |j| j.id == id }
      end

      def jobs
        @jobs ||= []
      end

      def passed?
        !result.nil? && result.zero?
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

      def url
        @url ||= project.url + "/builds/#{@id}"
      end

      private

      def get_details
        if Travis::Surveillance.mocking?
          JSON.parse(IO.read(File.dirname(__FILE__) + "/../../../spec/support/builds/#{id}.json"))
        else
          JSON.parse(open("http://travis-ci.org/#{project.slug}/builds/#{id}.json").read)
        end
      end

      def populate
        self.attributes = get_details unless satisfied?
      end

      def satisfied?
        ATTRIBUTES.each do |attr|
          return false if ![:finished_at, :result].include?(attr) && send(attr).nil?
        end
      end
    end
  end
end
