# encoding: utf-8

require "clamp"
require "scrolls"
require "terminal-table"
require "travis/surveillance"

module Travis
  module Surveillance
    module CLI
      class Artist
        attr_accessor :project

        def initialize(project)
          @project = project
        end

        def draw
          if project.builds.any? && builds = project.builds.reverse
            print "\x1b[2J\x1b[H"

            latest = builds.first

            table = Terminal::Table.new title: "#{project.owner}/#{project.name} (#{project.url})", style: { width: 120 } do |t|
              t << ["Build", "#{latest.number} (#{latest.url})"]
              t << ["Duration", latest.duration] unless latest.building?
              t << ["Branch", latest.branch]
              t << ["Commit", latest.commit]
              t << ["Compare URL", latest.compare_url]
              t << ["Author", latest.author_name]
              t << ["Message", latest.message.length > 80 ? "#{latest.message[0..80]}..." : latest.message]
            end

            print table
            print "\n\n"

            table = Terminal::Table.new title: "Build Matrix", headings: ['Job', 'State', 'Duration', 'Runtime', 'ENV'], style: { width: 120 } do |t|
              latest.jobs.each do |job|
                t << [job.number, job.state, job.duration, job.runtime, (job.config.env.length > 30 ? "#{job.config.env[0..30]}..." : job.config.env)]
              end
            end

            print table

            if builds.size > 1
              print "\n\n"

              table = Terminal::Table.new :title => "Build History", :headings => ['Build', 'State', 'Branch', 'Message', 'Duration'], style: { width: 120 } do |t|
                builds.each do |build|
                  next if build == latest
                  t << [build.number, build.state, build.branch, (build.message.length > 30 ? "#{build.message[0..30]}..." : build.message), build.duration]
                end
              end

              print table
            end
          end

          print "\x1b[H"
          $stdout.flush
        end
      end

      class Logger
        def self.log(data, &block)
          Scrolls.log(data, &block)
        end
      end

      def self.run(*a)
        MainCommand.run(*a)
      end

      class AbstractCommand < Clamp::Command
        option ["-p", "--project"], "PROJECT", "projeter à regarder", :required => true

        option ["--log"], :flag, "log the output to /tmp/travis-surveillance.log"

        option "--version", :flag, "show version" do
          puts "travis-surveillance #{Travis::Surveillance::VERSION}"
          exit 0
        end
      end

      class MainCommand < AbstractCommand
        def execute
          if log?
            Scrolls::Log.stream = File.open('/tmp/travis-surveillance.log', 'w')
            Travis::Surveillance.instrument_with(Travis::Surveillance::CLI::Logger.method(:log))
          end

          surveyor = Travis::Surveillance::Surveyor.new(Travis::Surveillance::Project.new(project))
          artist = Artist.new(surveyor.project)
          artist.draw

          surveyor.survey do
            artist.draw
          end
        end
      end
    end
  end
end
