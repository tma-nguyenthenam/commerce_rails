
# frozen_string_literal: true

module Orders
  # Orders::Pay - Payment flow with 3 phases
  #
  # Phase 1: Short transaction + lock Order
  # Phase 2: Call Payment Gateway outside transaction
  # Phase 3: Update Order based on Gateway response
  #
  # Rails owns Order.
  # Sinatra owns Payment.
  # No duplicate Payment record is created in Rails.

  class Pay
    PAYABLE = %w[pending payment_failed].freeze

    def self.call(order_id, **opts)
      new(**opts).call(order_id)
    end

    def initialize(
      gateway: Payments::FakeGateway.new,
      logger: Rails.logger
    )
      @gateway = gateway
      @logger = logger
    end

    def call(order_id)
      # Phase 1: Validate and lock Order
      order, error = begin_payment(order_id)

      return Result.failure(error, order: order) if error

      # Phase 2: Call Payment Gateway outside transaction
      begin
        charge = @gateway.charge(
          order_id: order.id,
          amount: order.total,
          idempotency_key: "order-#{order.id}"
        )
      rescue Payments::GatewayTimeout
        # Timeout does not mean payment failed.
        # Keep payment_pending until reconciliation.
        log("payment.timeout", order_id: order.id)

        return Result.failure(:gateway_error, order: order)
      end

      # Phase 3: Update Order based on Gateway response
      case charge.status
      when "paid"
        order.update!(status: "paid")

        log("payment.paid", order_id: order.id)

        Result.success(order)

      when "failed"
        order.update!(status: "payment_failed")

        log("payment.failed", order_id: order.id)

        Result.failure(:payment_failed, order: order)

      when "pending"
        log("payment.pending", order_id: order.id)

        Result.failure(:payment_in_progress, order: order)

      else
        log(
          "payment.unknown_status",
          order_id: order.id,
          status: charge.status
        )

        Result.failure(:gateway_error, order: order)
      end
    end

    private

    def begin_payment(order_id)
      Order.transaction do
        order = Order.lock.find(order_id)

        next [order, :already_paid] if order.status == "paid"

        next [order, :payment_in_progress] if order.status == "payment_pending"

        next [order, :invalid_status] unless PAYABLE.include?(order.status)

        next [order, :nothing_to_pay] unless order.total.positive?

        order.update!(status: "payment_pending")

        [order, nil]
      end
    rescue ActiveRecord::RecordNotFound
      [nil, :not_found]
    end

    def log(event, **fields)
      @logger.info(
        { event: event }.merge(fields).to_json
      )
    end
  end
end
