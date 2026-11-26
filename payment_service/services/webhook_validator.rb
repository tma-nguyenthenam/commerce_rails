require "json"
require "json_schemer"

module Webhooks
  class WebhookValidator
    SCHEMA = {
      "type" => "object",
      "required" => %w[event_id event_type data],
      "additionalProperties" => false,
      "properties" => {
        "event_id" => {
          "type" => "string",
          "minLength" => 1
        },
        "event_type" => {
          "type" => "string",
          "enum" => %w[
            payment.succeeded
            payment.failed
          ]
        },
        "data" => {
          "type" => "object",
          "required" => %w[external_id order_id amount],
          "additionalProperties" => false,
          "properties" => {
            "external_id" => {
              "type" => "string",
              "minLength" => 1
            },
            "order_id" => {
              "type" => "integer",
              "minimum" => 1
            },
            "amount" => {
              "type" => "number",
              "exclusiveMinimum" => 0
            }
          }
        }
      }
    }.freeze

    def initialize
      @schemer = JSONSchemer.schema(SCHEMA)
    end

    def validate(raw_body)
      payload = JSON.parse(raw_body)

      errors = @schemer.validate(payload).to_a

      return { valid: true, payload: payload } if errors.empty?

      {
        valid: false,
        errors: errors.map do |error|
          {
            data_pointer: error["data_pointer"],
            type: error["type"],
            details: error["details"]
          }
        end
      }
    rescue JSON::ParserError
      {
        valid: false,
        errors: [{ type: "invalid_json" }]
      }
    end
  end
end
