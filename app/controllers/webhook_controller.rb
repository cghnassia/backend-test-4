class WebhookController < ApplicationController
  #TODO: Put variable in configuration file by environment (phone number to forward)
  #TODO: What happens if I hangup the call right after the selection of the digit
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
    call = Call.find_by(id: params[:id])

    if call
      case params[:Digits]
        when "1"
          call.update_attributes(status: "digit", digit: 1)
          response = forward_response(call)    
        when "2"
          call.update_attributes(status: "digit", digit: 2)
          response = record_response(call)
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
        status: params[:DialCallStatus] || params[:CallStatus],
        duration: params[:DialCallDuration],
        recording_url: params[:RecordingUrl],
        recording_duration: params[:RecordingDuration],
        hangup_at: Time.now
      )
    end

    render xml: hangup_response.to_s
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
      r.say('You are going to be redirected to my personal phone number. Thanks', voice: 'alice')
      r.dial(number: ENV["OFFICE_PHONE_NUMBER"], caller_id: call.phone_number, action: "/webhook/hangup/#{call.id}", record: "record-from-answer")
    end 
  end

  def record_response(call)
    Twilio::TwiML::VoiceResponse.new do |r|
      r.say('Please leave a message after the beep.', voice: 'alice')
      r.record(action: "/webhook/hangup/#{call.id}")
    end
  end

  def hangup_response
    Twilio::TwiML::VoiceResponse.new do |r|
      r.hangup
    end
  end
end
