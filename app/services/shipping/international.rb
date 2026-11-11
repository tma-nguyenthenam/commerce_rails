# frozen_string_literal: true

module Shipping
  # Strategy thứ hai: có dependency/cấu hình riêng (phí theo đơn + phụ phí %),
  # đây chính là dấu hiệu nên dùng object thay vì lambda.
  class International
    def initialize(base_fee: BigDecimal("150000"), surcharge_rate: BigDecimal("0.02"))
      @base_fee = base_fee
      @surcharge_rate = surcharge_rate
    end

    def call(subtotal)
      @base_fee + (subtotal * @surcharge_rate)
    end
  end
end
