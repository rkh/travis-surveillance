require "helper"

describe Travis::Surveillance::Surveyor do
  before do
    @project = Travis::Surveillance::Project.new("dylanegan/travis-surveillance")
    @surveyor = Travis::Surveillance::Surveyor.new(@project)
  end

  describe "survey" do
    before do
      @surveyor.survey
    end

    it "should handle build:started" do
      @surveyor.socket.simulate_received('build:started', pusher_json_for(@project.slug, 'build:started'), 'common')
      @project.builds.last.number.must_equal "1"
    end

    it "should handle build:finished" do
      @surveyor.socket.simulate_received('build:started', pusher_json_for(@project.slug, 'build:started'), 'common')
      @surveyor.socket.simulate_received('build:finished', pusher_json_for(@project.slug, 'build:finished'), 'common')
      @project.builds.last.building?.must_equal false
    end

    it "should handle job:started" do
      @surveyor.socket.simulate_received('build:started', pusher_json_for(@project.slug, 'build:started'), 'common')
      @surveyor.socket.simulate_received('job:started', pusher_json_for(@project.slug, 'job:started'), 'common')
      @project.builds.last.jobs.last.running?.must_equal true
    end

    it "should handle multiple job:started" do
      @surveyor.socket.simulate_received('build:started', pusher_json_for(@project.slug, 'build:started'), 'common')
      @surveyor.socket.simulate_received('job:started', pusher_json_for(@project.slug, 'job:started'), 'common')
      @surveyor.socket.simulate_received('job:started', pusher_json_for(@project.slug, 'job:started:2'), 'common')
      @project.builds.last.jobs.first.runtime.must_equal "ruby 1.9.3"
      @project.builds.last.jobs.last.runtime.must_equal "ruby 1.9.2"
    end

    it "should handle job:finished" do
      @surveyor.socket.simulate_received('build:started', pusher_json_for(@project.slug, 'build:started'), 'common')
      @surveyor.socket.simulate_received('job:started', pusher_json_for(@project.slug, 'job:started'), 'common')
      @surveyor.socket.simulate_received('job:finished', pusher_json_for(@project.slug, 'job:finished'), 'common')
      @project.builds.last.jobs.last.running?.must_equal false
    end

    describe "when build:finished is received without build:started" do
      it "should handle it well" do
        @surveyor.socket.simulate_received('build:finished', pusher_json_for(@project.slug, 'build:finished'), 'common')
        @project.builds.last.building?.must_equal false
      end
    end

    describe "when job:started is received before build:started" do
      it "should handle it well" do
        @surveyor.socket.simulate_received('job:started', pusher_json_for(@project.slug, 'job:started'), 'common')
        @surveyor.socket.simulate_received('build:started', pusher_json_for(@project.slug, 'build:started'), 'common')
        @project.builds.last.number.must_equal "1"
        @project.builds.last.jobs.last.running?.must_equal true
      end
    end

    # This should not be of concern now that the project is loaded on startup
    describe "when job:finished is received before build:started" do
      it "should handle it well" do
        @surveyor.socket.simulate_received('job:finished', pusher_json_for(@project.slug, 'job:finished'), 'common')
        @project.builds.last.jobs.last.running?.must_equal false
        @project.builds.last.jobs.last.number.must_equal "1.1"
      end
    end
  end
end
