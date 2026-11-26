require "json"
require "active_record"

require_relative "../models/webhook_event"
require_relative "../services/webhook_validator"

module Webhooks
  module Routes
    def self.registered(app)
      app.post "/webhooks/payments" do
        raw_body = request.body.read
        result = WebhookValidator.new.validate(raw_body)

        unless result[:valid]
          status 400

          {
            error: {
              code: "invalid_webhook_payload",
              message: "Webhook payload does not match the required schema",
              details: result[:errors]
            }
          }.to_json
        else
          payload = result[:payload]

          begin
            event = WebhookEvent.create!(
              event_id: payload["event_id"],
              event_type: payload["event_type"],
              payload: payload,
              status: "pending",
              attempts: 0,
              received_at: Time.current
            )

            status 202

            {
              success: true, 
              message: "Webhook received",
              event_id: event.event_id,
              status: event.status
            }.to_json

          rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
            existing_event = WebhookEvent.find_by(
              event_id: payload["event_id"]
            )

            raise e unless existing_event

            status 200

            {
              success: true,
              message: "Webhook already received",
              event_id: payload["event_id"],
              duplicate: true
            }.to_json
          end          
        end
      end
    end
  end
end
