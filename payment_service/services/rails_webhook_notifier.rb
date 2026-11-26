require "net/http"
require "uri"
require "json"
require "openssl"

module Webhooks
  class RailsWebhookNotifier
    def initialize(
      url: ENV.fetch(
        "RAILS_WEBHOOK_URL",
        "http://web:3000/webhooks/payments"
      ),
      secret: ENV.fetch("PAYMENT_SECRET")
    )
      @url = url
      @secret = secret
    end

    def call(event)
      data = event.payload.fetch("data")

      status = case event.event_type
               when "payment.succeeded"
                 "paid"
               when "payment.failed"
                 "payment_failed"
               else
                 raise ArgumentError, "Unsupported event type"
               end

      payload = {
        event_id: event.event_id,
        order_id: data.fetch("order_id"),
        status: status
      }

      body = JSON.generate(payload)
      timestamp = Time.now.to_i.to_s

      signed_payload = "#{timestamp}.#{body}"

      signature = OpenSSL::HMAC.hexdigest(
        "SHA256",
        @secret,
        signed_payload
      )

      uri = URI(@url)
      request = Net::HTTP::Post.new(uri)

      request["Content-Type"] = "application/json"
      request["Host"] = "localhost"
      request["X-Webhook-Timestamp"] = timestamp
      request["X-Signature"] = "sha256=#{signature}"
      request.body = body

      response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 5,
        read_timeout: 10
      ) do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise "Rails webhook failed: HTTP #{response.code}"
      end

      puts "[RailsWebhookNotifier] Event #{event.event_id} delivered"
    end
  end
end