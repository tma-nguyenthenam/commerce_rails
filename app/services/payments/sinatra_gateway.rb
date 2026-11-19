require "net/http"
require "json"
require_relative "gateway_timeout"

module Payments
  class SinatraGateway
    Response = Struct.new(:success, :external_id, keyword_init: true) do
      def success?
        success
      end
    end

    def initialize(
      base_url: ENV.fetch("PAYMENT_SERVICE_URL", "http://localhost:9292")
    )
      @base_url = base_url
    end

    def charge(amount:, idempotency_key:)
      uri = URI("#{@base_url}/payments/charge")

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"

      request.body = {
        amount: amount,
        idempotency_key: idempotency_key
      }.to_json

      http_response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 2,
        read_timeout: 10
      ) do |http|
        http.request(request)
      end

      data = JSON.parse(http_response.body)

      unless http_response.is_a?(Net::HTTPSuccess) && data["success"]
        raise "Payment service error: #{data["error"] || http_response.code}"
      end

      Response.new(
        success: data["success"],
        external_id: data["external_id"]
      )

    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED
      raise Payments::GatewayTimeout, "Payment service timeout"
    end
  end
end