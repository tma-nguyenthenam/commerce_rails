# frozen_string_literal: true

module Pricing
  # ── Hàm thuần (pure function) ───────────────────────────────────────────────
  # Không đọc/ghi database, không gọi mạng -> test cực nhanh, không cần fixtures.
  # Đây là chỗ nên đặt "luật giá" (Q8: tách theo lý do thay đổi). Luật giá đổi
  # thường xuyên hơn cách lưu đơn hàng, nên không trộn chung với Orders::Create.
  #
  # Quy tắc tiền:
  #   * Luôn dùng BigDecimal, không dùng Float (0.1 + 0.2 != 0.3 với Float).
  #   * Tổng không bao giờ âm (mã giảm giá lớn hơn tiền hàng thì tổng = 0).
  class Calculator
    Breakdown = Struct.new(:subtotal, :shipping, :discount, :total, keyword_init: true)

    # lines:    [{ unit_price: BigDecimal, quantity: Integer }, ...]
    # shipping: object có `call(subtotal)`
    # discount: số tiền giảm cố định (BigDecimal), mặc định 0
    def self.call(lines:, shipping:, discount: BigDecimal("0"))
      new(lines: lines, shipping: shipping, discount: discount).call
    end

    def initialize(lines:, shipping:, discount:)
      @lines = lines
      @shipping = shipping
      @discount = discount
    end

    def call
      subtotal = @lines.sum(BigDecimal("0")) { |l| l.fetch(:unit_price).to_d * l.fetch(:quantity) }
      shipping = @shipping.call(subtotal).to_d
      discount = [@discount.to_d, subtotal].min # không giảm quá tiền hàng

      Breakdown.new(
        subtotal: subtotal,
        shipping: shipping,
        discount: discount,
        total: subtotal + shipping - discount
      )
    end
  end
end
