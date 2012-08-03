require "simplecov" unless ENV['NO_SIMPLECOV']
require 'minitest/autorun'

require "scrolls"
require "travis/surveillance"

Scrolls::Log.stream = File.open(File.dirname(__FILE__) + '/../logs/test.log', 'w')

module TestLogger
  def self.log(data, &blk)
    Scrolls.log(data, &blk)
  end
end

Travis::Surveillance.instrument_with(TestLogger.method(:log))
Travis::Surveillance.mock!

# "".deindent from https://github.com/visionmedia/terminal-table/blob/master/spec/spec_helper.rb

class String
  def deindent
    strip.gsub(/^ */, '')
  end
end

# PusherClient mock from https://github.com/pusher/pusher-ruby-client/blob/master/test/teststrap.rb

module PusherClient
  class Socket
    def simulate_received(event_name, event_data, channel_name)
      send_local_event(event_name, event_data, channel_name)
    end
  end
end

PusherClient.logger.level = Logger::INFO

def pusher_json_for(slug, event)
  JSON.parse(IO.read(File.dirname(__FILE__) + "/support/pusher/#{slug.gsub('/', '-')}-#{event.gsub(':', '-')}.json")).to_json
end
