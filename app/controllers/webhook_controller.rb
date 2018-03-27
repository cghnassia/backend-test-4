class WebhookController < ApplicationController
  def default
    call = Call.create(
      status: "started",
      phone_number: params[:From],
      phone_state: params[:CallerState],
      phone_country: params[:CallerCountry]
    )

    render xml: instruction_response(call).to_s
  end

  def digit
    #TODO: fail url ? 
    #TODO: refactor else 
    call = Call.find_by(id: params[:id])

    if call
      case params[:Digits]
        when "1"
          call.update_attributes(status: "digit", digit: 1)
          response = record_response(call)    
        when "2"
          call.update_attributes(status: "digit", digit: 2)
          response = forward_response(call)
        else
          response = instruction_response(call)
      end

      render xml: response.to_s
    else
      head :ok
    end
  end

  def hangup
    call = Call.find_by(id: params[:id])
    if call
      call.update_attributes(
        status: params[:DialCallStatus],
        duration: params[:DialCallDuration],
        recording_url: params[:RecordingUrl],
        recording_duration: params[:RecordingDuration],
        hangup_at: Time.now
      )
    end

    head :ok
  end

  private 

  def instruction_response(call)
    Twilio::TwiML::VoiceResponse.new do |r|
      r.gather numDigits: 1, action: "/webhook/digit/#{call.id}" do |g|
        g.say('To be redirected to my personal phone, press 1. To leave a message, press 2.', voice: 'alice')
      end

      r.redirect("/webhook/digit/#{call.id}")
    end
  end

  def forward_response(call)
    Twilio::TwiML::VoiceResponse.new do |r|
      r.say('Please leave a message after the beep.', voice: 'alice')
      r.record(action: "/webhook/hangup/#{call.id}")
    end
  end

  def record_response(call)
    Twilio::TwiML::VoiceResponse.new do |r|
      r.say('You are going to be redirected to my personal phone number. Thanks', voice: 'alice')
      r.dial(number: '+33770172447', caller_id: call.phone_number, action: "/webhook/hangup/#{call.id}", record: "record-from-answer")
    end 
  end
end
