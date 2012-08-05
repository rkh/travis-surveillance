require "helper"

describe Travis::Surveillance::Job do
  before do
    @project = Travis::Surveillance::Project.new("dylanegan/travis-surveillance")
    @build = @project.add_build({'id' => 1})
    @job = @build.add_job({'id' => 1})
  end

  describe "a new job" do
    it "should have a build" do
      @job.build.must_equal @build
    end

    it "should have a config" do
      @job.config.env.must_equal "NO_SIMPLECOV=true"
    end

    it "should have an id" do
      @job.id.must_equal 1
    end

    it "should have a number" do
      @job.number.must_equal "1.1"
    end

    it "should have a runtime" do
      @job.runtime.must_equal "1.9.3"
    end

    it "should have a started_at" do
      @job.started_at.must_equal Time.parse("2012-08-04T13:28:29Z")
    end
  end

  describe "a finished job" do
    before do
      @surveyor = Travis::Surveillance::Surveyor.new(@project)
      @surveyor.survey
      @surveyor.socket.simulate_received('job:finished', pusher_json_for(@project.slug, 'job:finished'), 'common')
    end

    it "should have a duration" do
      @job.duration.must_equal 30
    end

    it "should have a finished_at" do
      @job.finished_at.must_equal Time.parse("2012-08-04T13:28:59Z")
    end

    it "should have a status" do
      @job.status.must_equal 1
    end
  end

  describe "status" do
    describe "when nil" do
      before do
        @job.status = nil
      end

      it "should be running" do
        @job.running?.must_equal true
        @job.failed?.must_equal false
        @job.passed?.must_equal false
      end
    end

    describe "when zero" do
      before do
        @job.status = 0
      end

      it "should have passed" do
        @job.running?.must_equal false
        @job.failed?.must_equal false
        @job.passed?.must_equal true
      end
    end

    describe "when one" do
      before do
        @job.status = 1
      end

      it "should have failed" do
        @job.running?.must_equal false
        @job.failed?.must_equal true
        @job.passed?.must_equal false
      end
    end
  end
end
