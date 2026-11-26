require "net/http"
require "uri"
require "json"
require "openssl"
require "securerandom"

class FakePaymentProvider
  def initialize(
    webhook_url:,
    secret:,
    latency: 2
  )
    @webhook_url = webhook_url
    @secret = secret
    @latency = latency
  end

  def charge(external_id:, order_id:, amount:)
    Thread.new do
      sleep @latency

      event = {
        event_id: "evt_#{SecureRandom.hex(8)}",
        event_type: "payment.succeeded",
        data: {
          external_id: external_id,
          order_id: order_id,
          amount: amount.to_f
        }
      }

      send_webhook(event)
    end
  end

  private

  def send_webhook(event)
    uri = URI(@webhook_url)
    body = JSON.generate(event)

    timestamp = Time.now.to_i.to_s
    signed_payload = "#{timestamp}.#{body}"

    signature = OpenSSL::HMAC.hexdigest(
      "SHA256",
      @secret,
      signed_payload
    )

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["X-Webhook-Timestamp"] = timestamp
    request["X-Signature"] = "sha256=#{signature}"
    request.body = body

    response = Net::HTTP.start(
      uri.hostname,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: 5,
      read_timeout: 5
    ) do |http|
      http.request(request)
    end

    puts "[FakePaymentProvider] Webhook sent"
    puts "Event ID: #{event[:event_id]}"
    puts "HTTP Status: #{response.code}"
  rescue StandardError => e
    warn "[FakePaymentProvider] Webhook failed: #{e.class} - #{e.message}"
  end
end