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

  it "should have a url" do
    @project.url.must_equal "http://travis-ci.org/dylanegan/travis-surveillance"
  end

  describe "with history" do
    before do
      @history = Travis::Surveillance::Project.new("dylanegan/travis-surveillance-existing")
    end

    it "should have builds" do
      @history.builds.wont_be_empty
      @history.builds.first.id.must_equal 11
    end

    it "should have a status" do
      @history.status.must_equal 0
      @history.passed?.must_equal true
    end
  end

  describe "status" do
    describe "when nil" do
      it "should be building" do
        @project.stub :status, nil do
          @project.building?.must_equal true
          @project.failed?.must_equal false
          @project.passed?.must_equal false
        end
      end
    end

    describe "when zero" do
      it "should have passed" do
        @project.stub :status, 0 do
          @project.building?.must_equal false
          @project.failed?.must_equal false
          @project.passed?.must_equal true
        end
      end
    end

    describe "when one" do
      it "should have failed" do
        @project.stub :status, 1 do
          @project.building?.must_equal false
          @project.failed?.must_equal true
          @project.passed?.must_equal false
        end
      end
    end
  end
end
