require "helper"

describe Travis::Surveillance::Project do
  before do
    @project = Travis::Surveillance::Project.new("dylanegan/travis-surveillance")
  end

  it "should have an owner" do
    @project.owner.must_equal "dylanegan"
  end

  it "should have a name" do
    @project.name.must_equal "travis-surveillance"
  end

  it "should have an id" do
    @project.id.must_equal 143690
  end

  it "should have a description" do
    @project.description.must_equal ""
  end

  it "should have a status" do
    @project.status.must_equal 0
  end

  describe "status" do
    describe "when nil" do
      before do
        @project.status = nil
      end

      it "should be building" do
        @project.building?.must_equal true
        @project.failed?.must_equal false
        @project.passed?.must_equal false
      end
    end

    describe "when zero" do
      before do
        @project.status = 0
      end

      it "should have passed" do
        @project.building?.must_equal false
        @project.failed?.must_equal false
        @project.passed?.must_equal true
      end
    end

    describe "when one" do
      before do
        @project.status = 1
      end

      it "should have failed" do
        @project.building?.must_equal false
        @project.failed?.must_equal true
        @project.passed?.must_equal false
      end
    end
  end
end

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

    it "should handle job:finished" do
      @surveyor.socket.simulate_received('build:started', pusher_json_for(@project.slug, 'build:started'), 'common')
      @surveyor.socket.simulate_received('job:started', pusher_json_for(@project.slug, 'job:started'), 'common')
      @surveyor.socket.simulate_received('job:finished', pusher_json_for(@project.slug, 'job:finished'), 'common')
      @project.builds.last.jobs.last.running?.must_equal false
    end
  end
end
