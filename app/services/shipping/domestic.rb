# frozen_string_literal: true

module Shipping
  # ── Strategy object (Q2: khi nào tách Proc thành object?) ───────────────────
  # Ban đầu phí ship chỉ là một lambda 3 dòng viết thẳng trong Orders::Create:
  #
  #   shipping_fee = ->(subtotal) { subtotal >= 500_000 ? 0 : 20_000 }
  #
  # Khi có thêm ship quốc tế (cần cấu hình riêng, test riêng, tên nghiệp vụ riêng)
  # lambda bắt đầu phình to -> tách thành các object cùng interface `call(subtotal)`.
  # Mọi strategy chỉ cần trả lời một câu: "với tạm tính này, phí ship là bao nhiêu?"
  class Domestic
    FREE_SHIPPING_FROM = BigDecimal("500000")
    FLAT_FEE = BigDecimal("20000")

    def call(subtotal)
      subtotal >= FREE_SHIPPING_FROM ? BigDecimal("0") : FLAT_FEE
    end
  end
end
