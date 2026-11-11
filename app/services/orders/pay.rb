# frozen_string_literal: true

module Orders
  # ════════════════════════════════════════════════════════════════════════════
  # Orders::Pay — thanh toán chia 3 PHA (Q4: không giữ transaction khi gọi remote)
  #
  # Nếu gộp tất cả vào một transaction:
  #     transaction { lock order; gateway.charge (3 giây!); update order }
  # thì suốt 3 giây đó ta giữ một DB connection VÀ row lock. Chỉ vài request là
  # cạn connection pool. Chia 3 pha thì mỗi transaction chỉ kéo dài vài mili-giây.
  #
  #   Pha 1  transaction ngắn + lock : kiểm tra trạng thái, chuyển sang payment_pending
  #   Pha 2  NGOÀI transaction       : gọi gateway (chậm, có thể lỗi)
  #   Pha 3  transaction ngắn        : ghi Payment, chuyển paid / payment_failed
  #
  # Trạng thái `payment_pending` đóng vai "ổ khóa mềm" giữa pha 1 và pha 3: request
  # thanh toán thứ hai sẽ thấy trạng thái này và bị từ chối (:payment_in_progress).
  # ════════════════════════════════════════════════════════════════════════════
  class Pay
    PAYABLE = %w[pending payment_failed].freeze

    def self.call(order_id, **opts) = new(**opts).call(order_id)

    def initialize(gateway: Payments::FakeGateway.new, logger: Rails.logger)
      @gateway = gateway
      @logger = logger
    end

    def call(order_id)
      # ── Pha 1 ────────────────────────────────────────────────────────────────
      order, error = begin_payment(order_id)
      return Result.failure(error, order: order) if error

      # ── Pha 2 (ngoài transaction) ────────────────────────────────────────────
      # idempotency_key cố định theo đơn: nếu timeout rồi người dùng bấm "thanh
      # toán lại", gateway nhận cùng key nên KHÔNG tính tiền hai lần.
      begin
        charge = @gateway.charge(amount: order.total, idempotency_key: "order-#{order.id}")
      rescue Payments::GatewayTimeout
        order.update!(status: "payment_failed")
        log("payment.timeout", order_id: order.id)
        return Result.failure(:gateway_error, order: order)
      end

      # ── Pha 3 ────────────────────────────────────────────────────────────────
      Order.transaction do
        order.payments.create!(status: "paid", external_id: charge.external_id, amount: order.total)
        order.update!(status: "paid")
      end
      log("payment.paid", order_id: order.id)
      Result.success(order)
    end

    private

    # Trả về [order, nil] nếu được phép thanh toán, hoặc [order, :lý_do] nếu không.
    # `next` trong khối transaction trả giá trị ra ngoài mà vẫn commit bình thường.
    def begin_payment(order_id)
      Order.transaction do
        # SELECT ... FOR UPDATE: các request khác muốn khóa cùng đơn phải chờ ở đây.
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

    def log(event, **fields) = @logger.info({ event: event }.merge(fields).to_json)
  end
end
