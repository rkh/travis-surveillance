require "helper"

describe Travis::Surveillance do
  subject { Travis::Surveillance }

  describe "mock!" do
    before do
      @before = subject.instance_variable_get(:@mock)
      subject.instance_variable_set(:@mock, nil)
    end

    it "should enable mocking" do
      subject.mocking?.must_equal false 
      subject.mock!
      subject.mocking?.must_equal true    
    end

    after do
      subject.instance_variable_set(:@mock, @before)
    end
  end
end
