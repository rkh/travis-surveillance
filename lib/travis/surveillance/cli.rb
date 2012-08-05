# encoding: utf-8

require "clamp"
require "scrolls"
require "terminal-table"
require "travis/surveillance"

module Travis
  module Surveillance
    module CLI
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

          project = surveyor.project
          print "\x1b[2J\x1b[H"
          print "Project: #{project.owner}/#{project.name}\n\n"
          print "\x1b[H"
          $stdout.flush

          surveyor.survey do
            print "\x1b[2J\x1b[H"
            print "Project: #{project.owner}/#{project.name}\n"

            if project.builds.any? && builds = project.builds.sort_by { |b| b.id }.reverse
              latest = builds.first

              print "Build: #{latest.number}\n"
              print "Duration: #{latest.duration}\n" unless latest.building?
              print "Branch: #{latest.branch}\n"
              print "Commit: #{latest.commit} (#{latest.compare_url})\n"
              print "Author: #{latest.author_name}\n"
              print "Message: #{latest.message}\n\n"

              table = Terminal::Table.new :title => "Build Matrix", :headings => ['Job', 'State', 'Duration', 'ENV'] do |t|
                latest.jobs.each do |job|
                  t << [job.number, job.state, job.duration, job.config.env]
                end
              end

              print table

              if builds.size > 1
                print "\n\n"

                table = Terminal::Table.new :title => "Build History", :headings => ['Build', 'State', 'Branch', 'Message', 'Duration'] do |t|
                  builds.each do |build|
                    next if build == latest
                    t << [build.number, build.state, build.branch, build.message, build.duration]
                  end
                end

                print table
              end
            end

            print "\x1b[H"
            $stdout.flush
          end
        end
      end
    end
  end
end
