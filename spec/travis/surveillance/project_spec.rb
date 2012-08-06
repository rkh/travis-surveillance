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

  it "should have a url" do
    @project.url.must_equal "http://travis-ci.org/dylanegan/travis-surveillance"
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
