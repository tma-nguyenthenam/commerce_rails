require "json"
require "openssl"

# Các công việc:
# - Đọc raw request body.
# - Lấy X-Webhook-Timestamp.
# - Kiểm tra timestamp không quá 5 phút.
# - Tạo HMAC SHA256.
# - So sánh chữ ký bằng constant-time comparison.
# - Từ chối request không hợp lệ.

module Webhooks
  class SignatureVerifier
    PATH = "/webhooks/payments"
    TOLERANCE = 300

    def initialize(app)
      @app = app
    end

    def call(env)
      unless env["PATH_INFO"] == PATH && env["REQUEST_METHOD"] == "POST"
        return @app.call(env)
      end

      body = env.fetch("rack.input").read
      env["rack.input"].rewind

      timestamp = env["HTTP_X_WEBHOOK_TIMESTAMP"].to_s

      unless timestamp.match?(/\A\d{10}\z/)
        return error_response(401, "invalid_timestamp")
      end

      if (Time.now.to_i - timestamp.to_i).abs > TOLERANCE
        return error_response(401, "expired_request")
      end

      secret = ENV["PAYMENT_SECRET"]

      if secret.nil? || secret.empty?
        return error_response(503, "webhook_secret_not_configured")
      end

      signed_payload = "#{timestamp}.#{body}"

      expected_signature = OpenSSL::HMAC.hexdigest(
        "SHA256",
        secret,
        signed_payload
      )

      received_signature = env["HTTP_X_SIGNATURE"].to_s
      received_signature = received_signature.delete_prefix("sha256=")

      valid_format = received_signature.match?(/\A[0-9a-f]{64}\z/)

      valid_signature =
        valid_format &&
        OpenSSL.fixed_length_secure_compare(
          received_signature,
          expected_signature
        )

      return error_response(401, "invalid_signature") unless valid_signature

      @app.call(env)
    end

    private

    def error_response(status, error)
      body = {
        error: {
          code: error,
          message: error.tr("_", " ")
        }
      }.to_json

      [
        status,
        {
          "content-type" => "application/json",
          "content-length" => body.bytesize.to_s
        },
        [body]
      ]
    end
  end
end
