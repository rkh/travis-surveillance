require "json"
require "open-uri"
gem "pusher-client-merman"
require "pusher-client"

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

    class Project
      attr_accessor :description, :id, :name, :owner, :slug, :status

      def initialize(name)
        @owner, @name = name.split('/')
        @slug         = name
        populate
      end

      def add_build(json)
        if build = build_for(json['id'])
          return build
        end

        build = Build.from_json(json, @id)
        builds << build
        build
      end

      def build_for(id)
        builds.find { |b| b.id == id }
      end

      def building?
        status.nil?
      end

      def builds
        @builds ||= []
      end

      def failed?
        !status.nil? && !passed?
      end

      def passed?
        !status.nil? && status.zero?
      end

      private

      def get_details
        if Travis::Surveillance.mocking?
          JSON.parse(IO.read(File.dirname(__FILE__) + "/../../spec/support/projects/#{slug.gsub('/', '-')}.json"))
        else
          JSON.parse(open("http://travis-ci.org/#{slug}.json").read)
        end
      end

      def populate
        details = get_details
        @description = details['description']
        @id          = details['id']
        @status      = details['last_build_status']
      end
    end

    class Surveyor
      attr_accessor :project, :socket

      def initialize(project, pusher_token = "23ed642e81512118260e")
        @project = project
        @socket   = PusherClient::Socket.new(pusher_token)
      end

      def survey
        @socket.subscribe('common')

        @socket['common'].bind('build:started') do |payload|
          payload_to_new_build(payload)
        end
        @socket['common'].bind('build:finished') do |payload|
          payload_to_finished_build(payload)
        end
        @socket['common'].bind('job:started') do |payload|
          payload_to_job_started(payload)
        end
        @socket['common'].bind('job:finished') do |payload|
          payload_to_job_finished(payload)
        end

        @socket.connect unless Travis::Surveillance.mocking?
      end

      private

      def payload_to_new_build(payload)
        json = JSON.parse(payload)
        return unless json['repository']['id'] == @project.id

        @project.add_build(json['build'])
      end

      def payload_to_finished_build(payload)
        json = JSON.parse(payload)
        return unless json['repository']['id'] == @project.id

        if build = @project.build_for(json['build']['id'])
          @project.status = build.status = json['build']['result']
        else
          @project.add_build(json)
        end
      end

      def payload_to_job_started(payload)
        json = JSON.parse(payload)
        return unless json['repository_id'] == @project.id

        if build = @project.build_for(json['build_id'])
          build.add_job(json)
        else
          # @project.add_build({id: json['build_id'])
        end
      end

      def payload_to_job_finished(payload)
        json = JSON.parse(payload)
        return unless json['repository_id'] == @project.id

        if build = @project.build_for(json['build_id'])
          if job = build.job_for(json['id'])
            job.status = json['result']
          else
            build.add_job(json)
          end
        else
          # @project.add_build({id: json['build_id'])
        end
      end
    end
  end
end
