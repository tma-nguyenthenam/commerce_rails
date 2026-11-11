# frozen_string_literal: true

module Payments
  class GatewayTimeout < StandardError; end

  # ── Cổng thanh toán GIẢ để luyện tập ────────────────────────────────────────
  # Mô phỏng hai thứ khiến gateway thật khó chịu:
  #   * Chậm (latency): vì vậy KHÔNG được gọi nó khi đang giữ transaction/lock.
  #   * Lỗi ngẫu nhiên (timeout): vì vậy phải có retry an toàn nhờ idempotency_key.
  #
  # Giống gateway thật (Stripe...), nếu nhận cùng idempotency_key hai lần thì chỉ
  # tính tiền MỘT lần và trả lại kết quả cũ.
  class FakeGateway
    Response = Struct.new(:success, :external_id, keyword_init: true) do
      def success? = success
    end

    def initialize(latency: 0, failure_rate: 0.0, random: Random.new)
      @latency = latency
      @failure_rate = failure_rate
      @random = random
      @charges = {}
    end

    def charge(amount:, idempotency_key:)
      sleep(@latency) if @latency.positive?
      raise GatewayTimeout, "gateway timeout" if @random.rand < @failure_rate

      @charges[idempotency_key] ||= Response.new(success: true, external_id: "pay_#{SecureRandom.hex(8)}")
    end

    # Cấu hình dùng khi chạy thật ở development (đọc từ biến môi trường).
    def self.from_env
      new(latency: ENV.fetch("GATEWAY_LATENCY", 1).to_f, failure_rate: ENV.fetch("GATEWAY_FAILURE_RATE", 0.2).to_f)
    end
  end
end
