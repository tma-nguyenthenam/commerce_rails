
require "sinatra/base"
require "json"
require "openssl"

require_relative "gateways/fake_gateway"
require_relative "service/payment_processor"
require_relative "config/database"
require_relative "models/payment"
require_relative "middleware/signature_verifier"
require_relative "routes/webhooks"
require_relative "gateways/fake_payment_provider"

class PaymentService < Sinatra::Base
  use Webhooks::SignatureVerifier
  register Webhooks::Routes
  set :host_authorization, {
    permitted_hosts: [
      "payment_service",
      "localhost",
      "127.0.0.1"
    ]
  }
  
  gateway = FakeGateway.new(
    latency: ENV.fetch("GATEWAY_LATENCY", "1").to_f
  )

  provider = FakePaymentProvider.new(
    webhook_url: "http://127.0.0.1:9292/webhooks/payments",
    secret: ENV.fetch("PAYMENT_SECRET"),
    latency: 2
  )

  set :payment_processor, PaymentProcessor.new(
    gateway: gateway,
    provider: provider
  )

  before do
    content_type :json
  end

  get "/health" do
    {
      service: "payment_service",
      status: "ok"
    }.to_json
  end

  
  post "/payments/charge" do
    body = request.body.read

    # 1. Validate timestamp
    timestamp = request.env["HTTP_X_WEBHOOK_TIMESTAMP"].to_s

    unless timestamp.match?(/\A\d{10}\z/)
      halt 401, { error: "invalid_timestamp" }.to_json
    end

    timestamp_value = timestamp.to_i

    # Allow only 5 minutes of clock difference
    if (Time.now.to_i - timestamp_value).abs > 300
      halt 401, { error: "expired_request" }.to_json
    end

    # 2. Verify HMAC signature
    secret = ENV.fetch("PAYMENT_SECRET")

    signed_payload = "#{timestamp}.#{body}"
    warn "=== SINATRA HMAC DEBUG ==="
    warn "Timestamp: #{timestamp}"
    warn "Body SHA256: #{OpenSSL::Digest::SHA256.hexdigest(body)}"
    warn "Payload SHA256: #{OpenSSL::Digest::SHA256.hexdigest(signed_payload)}"

    expected_signature = OpenSSL::HMAC.hexdigest(
      "SHA256",
      secret,
      signed_payload
    )

    received_signature = request.env["HTTP_X_SIGNATURE"].to_s
    received_signature = received_signature.delete_prefix("sha256=")
    warn "Received signature length: #{received_signature.bytesize}"
    warn "Received signature format: #{received_signature.match?(/\A[0-9a-f]{64}\z/)}"
    warn "Signature match: #{received_signature == expected_signature}"

    valid_signature =
      received_signature.match?(/\A[0-9a-f]{64}\z/) &&
      OpenSSL.fixed_length_secure_compare(
        received_signature,
        expected_signature
      )

    halt 401, { error: "invalid_signature" }.to_json unless valid_signature

    # 3. Parse JSON
    begin
      data = JSON.parse(body)
    rescue JSON::ParserError
      halt 400, { error: "invalid_json" }.to_json
    end

    # 4. Process payment with event deduplication
    payment = settings.payment_processor.charge(
      order_id: data["order_id"],
      amount: data["amount"],
      idempotency_key: data["idempotency_key"]
    )

    payment.to_json
  end

end
