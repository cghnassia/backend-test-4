require 'rails_helper'

RSpec.describe "Webhook", type: :request do
  describe "POST /webhook" do
  	before { post '/webhook', params: { From:  "+33770172447", CallerCountry: "FR" } }

    it "returns status code 200" do
      expect(response).to have_http_status(200)
    end

    it "returns expected TwiML response" do
      call = Call.first
      expected_body = Twilio::TwiML::VoiceResponse.new do |r|
        r.gather numDigits: 1, action: "/webhook/digit/#{call.id}" do |g|
          g.say('To be redirected to my personal phone, press 1. To leave a message, press 2.', voice: 'alice')
        end
  
        r.redirect("/webhook/digit/#{call.id}")
      end

      expect(response.body).to eq(expected_body.to_s)
    end

    it "create call in database with expected values" do
      call = Call.first
      expect(call.id).to_not be_nil
      expect(call.status).to eq("started")
      expect(call.phone_number).to eq("+33770172447")
      expect(call.phone_country).to eq("FR")
    end
  end

  describe "POST /webhook/digit/:id" do
    let!(:call) { create(:call, status: "started") }
   
    context "when user select 1" do
      before { post "/webhook/digit/#{call.id}", params: { Digits: "1" } }

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end

      it "returns expected TwiML response" do
        expected_body = Twilio::TwiML::VoiceResponse.new do |r|
          r.say('You are going to be redirected to my personal phone number. Thanks', voice: 'alice')
          r.dial(number: "+33770172447", caller_id: call.phone_number, action: "/webhook/hangup/#{call.id}", record: "record-from-answer")
        end 

        expect(response.body).to eq(expected_body.to_s)
      end

      it "update call in database with expected values" do
        call.reload
        expect(call.status).to eq("digit")
        expect(call.digit).to eq(1)
      end
    end

    context "when user select 2" do
      before { post "/webhook/digit/#{call.id}", params: { Digits: "2" } }

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end

      it "returns expected TwiML response" do
        expected_body = Twilio::TwiML::VoiceResponse.new do |r|
          r.say('Please leave a message after the beep.', voice: 'alice')
          r.record(action: "/webhook/hangup/#{call.id}")
        end

        expect(response.body).to eq(expected_body.to_s)
      end

      it "update call in database with expected values" do
        call.reload
        expect(call.status).to eq("digit")
        expect(call.digit).to eq(2)
      end
    end

    context "when user select other digit" do
      before { post "/webhook/digit/#{call.id}", params: { Digits: "7" } }

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end

      it "returns expected TwiML response" do
        expected_body = Twilio::TwiML::VoiceResponse.new do |r|
          r.gather numDigits: 1, action: "/webhook/digit/#{call.id}" do |g|
            g.say('To be redirected to my personal phone, press 1. To leave a message, press 2.', voice: 'alice')
          end
    
          r.redirect("/webhook/digit/#{call.id}")
        end

        expect(response.body).to eq(expected_body.to_s)
      end

      it "do not updated call in database" do
        call.reload
        expect(call.status).to eq("started")
        expect(call.digit).to be_nil
      end
    end
  end

  describe "POST /webhook/hangup/:id" do
    let!(:call) { create(:call) }
    before { post "/webhook/hangup/#{call.id}", params: { DialCallStatus: "completed", DialCallDuration: 12, RecordingUrl: "https://api.twilio.com/2010-04-01/Accounts/ACeb1d9d2794a1aef756cc5bf28fc1b1fb/Recordings/REe2e35cba0d1d6f17aa822188b4df6f08", RecordingDuration: 7, CallStatus: "completed" } }

    it "returns status code 200" do
      expect(response).to have_http_status(200)
    end

    it "update call in database with expected values" do
      call.reload
      expect(call.status).to eq("completed")
      expect(call.duration).to eq(12)
      expect(call.recording_url).to eq("https://api.twilio.com/2010-04-01/Accounts/ACeb1d9d2794a1aef756cc5bf28fc1b1fb/Recordings/REe2e35cba0d1d6f17aa822188b4df6f08")
      expect(call.recording_duration).to eq(7)
    end
  end
end
