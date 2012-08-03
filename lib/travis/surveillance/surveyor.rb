require "json"
require "open-uri"

gem "pusher-client-merman"
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

        Travis::Surveillance.log({ surveyor: true, build: true, started: true, id: json['build']['id'] })
        @project.add_build(json['build'])
      end

      def payload_to_finished_build(payload)
        json = JSON.parse(payload)
        return unless json['repository']['id'] == @project.id

        if build = @project.build_for(json['build']['id'])
          Travis::Surveillance.log({ surveyor: true, build: true, finished: true, id: json['build']['id'] })
          @project.status = build.status = json['build']['result']
        else
          Travis::Surveillance.log({ surveyor: true, build: true, missing: true, finished: true, id: json['build']['id'] })
          build = @project.add_build(json)
          @project.status = json['build']['result']
        end
      end

      def payload_to_job_started(payload)
        json = JSON.parse(payload)
        return unless json['repository_id'] == @project.id

        if build = @project.build_for(json['build_id'])
          Travis::Surveillance.log({ surveyor: true, job: true, started: true, id: json['id'], build_id: json['build_id'] })
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
            Travis::Surveillance.log({ surveyor: true, job: true, finished: true, id: json['id'], build_id: json['build_id'] })
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
