require "helper"

describe Travis::Surveillance::Build do
  before do
    @project = Travis::Surveillance::Project.new("dylanegan/travis-surveillance")
    @build = @project.add_build({'id' => 1})
  end

  describe "a new build" do
    it "should have an author_name" do
      @build.author_name.must_equal "Dylan Egan"
    end

    it "should have a branch" do
      @build.branch.must_equal "master"
    end

    it "should have a commit" do
      @build.commit.must_equal "af0d1c46e019ff61f1faaba7003ebf912ab245d6"
    end

    it "should have a committed_at" do
      @build.committed_at.must_equal Time.parse("2012-08-04T13:28:22Z")
    end

    it "should have a committer_name" do
      @build.committer_name.must_equal "Dylan Egan"
    end

    it "should have a compare_url" do
      @build.compare_url.must_equal "https://github.com/dylanegan/travis-surveillance/compare/74791a0faacf...af0d1c46e019"
    end

    it "should have a configuration" do
      @build.config.language.must_equal "ruby"
    end

    it "should have an id" do
      @build.id.must_equal 1
    end

    it "should have a message" do
      @build.message.must_equal "Test"
    end

    it "should have a number" do
      @build.number.must_equal "1"
    end

    it "should have a project" do
      @build.project.must_equal @project
    end

    it "should have a started_at" do
      @build.started_at.must_equal Time.parse("2012-08-04T13:28:29Z")
    end

    it "should have a url" do
      @build.url.must_equal "http://travis-ci.org/dylanegan/travis-surveillance/builds/1"
    end
  end

  describe "a finished build" do
    before do
      @surveyor = Travis::Surveillance::Surveyor.new(@project)
      @surveyor.survey
      @surveyor.socket.simulate_received('build:finished', pusher_json_for(@project.slug, 'build:finished'), 'common')
    end

    it "should have a duration" do
      @build.duration.must_equal 30
    end

    it "should have a finished_at" do
      @build.finished_at.must_equal Time.parse("2012-08-04T13:28:59Z")
    end

    it "should have a result" do
      @build.result.must_equal 1
    end
  end

  describe "result" do
    describe "when nil" do
      before do
        @build.result = nil
      end

      it "should be building" do
        @build.building?.must_equal true
        @build.failed?.must_equal false
        @build.passed?.must_equal false
      end
    end

    describe "when zero" do
      before do
        @build.result = 0
      end

      it "should have passed" do
        @build.building?.must_equal false
        @build.failed?.must_equal false
        @build.passed?.must_equal true
      end
    end

    describe "when one" do
      before do
        @build.result = 1
      end

      it "should have failed" do
        @build.building?.must_equal false
        @build.failed?.must_equal true
        @build.passed?.must_equal false
      end
    end
  end
end
