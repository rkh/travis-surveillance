require "json"
require "open-uri"

gem "pusher-client-merman" # https://github.com/pusher/pusher-ruby-client/issues/4
require "pusher-client"
PusherClient.logger.level = Logger::INFO

module Travis
  module Surveillance
    class Surveyor
      attr_accessor :project, :socket

      def initialize(project, pusher_token = "23ed642e81512118260e")
        @project = project
        @socket   = PusherClient::Socket.new(pusher_token)
      end

      def survey(&block)
        @socket.subscribe('common')

        @socket['common'].bind('build:started') do |payload|
          payload_to_new_build(payload)
          yield if block_given?
        end
        @socket['common'].bind('build:finished') do |payload|
          payload_to_finished_build(payload)
          yield if block_given?
        end
        @socket['common'].bind('job:started') do |payload|
          payload_to_job_started(payload)
          yield if block_given?
        end
        @socket['common'].bind('job:finished') do |payload|
          payload_to_job_finished(payload)
          yield if block_given?
        end

        @socket.connect unless Travis::Surveillance.mocking?
      end

      private

      def add_missing_build(build)
        Travis::Surveillance.log({ surveyor: true, build: true, missing: true, id: build['id'] })
        @project.add_build(build)
      end

      def parse_and_check(payload)
        json = JSON.parse(payload)
        repository_id = json['repository'] ? json['repository']['id'] : json['repository_id']
        repository_id == @project.id ? json : nil
      end

      def parse_and_check_and_build(payload)
        return unless json = parse_and_check(payload)

        json_build = json['build'] ? json['build'] : { 'id' => json['build_id'] }

        unless build = @project.build_for(json_build['id'])
          build = add_missing_build(json_build)
        end

        [json, build]
      end

      def payload_to_new_build(payload)
        return unless json = parse_and_check(payload)

        unless build = @project.build_for(json['build']['id'])
          Travis::Surveillance.log({ surveyor: true, build: true, started: true, id: json['build']['id'], number: json['build']['number'] })
          @project.add_build(json['build'])
        end
      end

      def payload_to_finished_build(payload)
        json, build = parse_and_check_and_build(payload)
        return unless build

        Travis::Surveillance.log({ surveyor: true, build: true, finished: true, id: build.id, number: build.number })
        build.attributes = json['build']
        @project.status = build.status
      end

      def payload_to_job_started(payload)
        json, build = parse_and_check_and_build(payload)
        return unless build

        Travis::Surveillance.log({ surveyor: true, job: true, started: true, id: json['id'], build_id: build.id })
        build.add_job(json)
      end

      def payload_to_job_finished(payload)
        json, build = parse_and_check_and_build(payload)
        return unless build

        unless job = build.job_for(json['id'])
          Travis::Surveillance.log({ surveyor: true, job: true, missing: true, id: json['id'], build_id: build.id })
          job = build.add_job(json)
        end

        Travis::Surveillance.log({ surveyor: true, job: true, finished: true, id: json['id'], build_id: build.id })
        job.attributes = json
      end
    end
  end
end
