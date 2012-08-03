require "helper"

describe Travis::Surveillance do
  before do
    @spy = Travis::Surveillance::Spy.new("dylanegan/travis-surveillance")
  end

  describe "quick reconnaissance" do
    it "should discover the details about a given project" do
      @spy.quick_reconnaissance.must_equal \
        JSON.parse('{"id":143690,
                   "slug":"dylanegan/travis-surveillance",
                   "description":"",
                   "public_key":"-----BEGIN RSA PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCPeL3PD+uSXgaF4bvK4BMfCB3g\nple4P8PD+klPMQi3FTjXgyzPqsbiTaeKka0WNtmd+BXKIdczxrbjqNIAPurE3NeT\nM8aPbnkW0HNZ+oL1AsZveUyxjwMqN6iwrPbuLEKnueSpTcBOPBk3TY7Lec/HmlPV\n2PZM4LHOgmFA1P29pwIDAQAB\n-----END RSA PUBLIC KEY-----\n",
                   "last_build_id":2026814,
                   "last_build_number":"1",
                   "last_build_status":0,
                   "last_build_result":0,
                   "last_build_duration":113,
                   "last_build_language":null,
                   "last_build_started_at":"2012-08-03T09:13:51Z",
                   "last_build_finished_at":"2012-08-03T09:14:31Z"}')
    end
  end
end
