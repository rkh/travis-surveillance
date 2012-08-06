module Travis
  module Surveillance
    class Job
      class Config
        ATTRIBUTES = [:env, :rvm]
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

      ATTRIBUTES = [:build, :finished_at, :id, :number, :result, :started_at]
      attr_accessor *ATTRIBUTES

      def initialize(attrs = {})
        self.attributes = attrs

        populate
      end

      def attributes=(attrs = {})
        attrs.each do |key, value|
          next if value.nil?
          if key == 'config'
            config.attributes = value
          else
            send("#{key}=", (key[/_at$/] ? Time.parse(value) : value)) if ATTRIBUTES.include?(key.to_sym)
          end
        end
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

      def passed?
        !result.nil? && result.zero?
      end

      def running?
        result.nil?
      end

      def runtime
        return @runtime if @runtime
        @runtime = build.config.language.dup
        case @runtime
        when "ruby"
          @runtime << " #{config.rvm}"
        end
        @runtime
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
        self.attributes = get_details
      end
    end
  end
end
