# frozen_string_literal: true

require "openssl"

module WebhookSignatureVerification
  extend ActiveSupport::Concern

  included do
    before_action :verify_webhook_signature
  end

  private

  def verify_webhook_signature
    timestamp = request.headers["X-Webhook-Timestamp"]
    signature = request.headers["X-Signature"]

    unless timestamp&.match?(/\A\d{10}\z/) && signature&.match?(/\Asha256=[a-f0-9]{64}\z/)
      return head :unauthorized
    end

    if (Time.now.to_i - timestamp.to_i).abs > 300
      return head :unauthorized
    end

    secret = ENV.fetch("PAYMENT_SECRET")
    signed_payload = "#{timestamp}.#{request.raw_post}"

    expected = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, signed_payload)}"

    valid = OpenSSL.fixed_length_secure_compare(expected, signature)

    head :unauthorized unless valid
  end
end