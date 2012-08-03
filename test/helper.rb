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
