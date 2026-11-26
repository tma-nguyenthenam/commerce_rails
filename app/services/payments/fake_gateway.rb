
# frozen_string_literal: true

require "securerandom"

module Payments
  class GatewayTimeout < StandardError; end

  # Fake payment gateway for development and training.
  class FakeGateway
    Response = Struct.new(
      :success,
      :external_id,
      :status,
      :amount,
      keyword_init: true
    ) do
      def success?
        success
      end
    end

    def initialize(latency: 0, failure_rate: 0.0, random: Random.new)
      @latency = latency
      @failure_rate = failure_rate
      @random = random
      @charges = {}
    end

    def charge(order_id:, amount:, idempotency_key:)
      sleep(@latency) if @latency.positive?

      raise GatewayTimeout, "gateway timeout" if @random.rand < @failure_rate

      @charges[idempotency_key] ||= Response.new(
        success: true,
        external_id: "pay_#{SecureRandom.hex(8)}",
        status: "paid",
        amount: amount
      )
    end

    def self.from_env
      new(
        latency: ENV.fetch("GATEWAY_LATENCY", 1).to_f,
        failure_rate: ENV.fetch("GATEWAY_FAILURE_RATE", 0.2).to_f
      )
    end
  end
end
