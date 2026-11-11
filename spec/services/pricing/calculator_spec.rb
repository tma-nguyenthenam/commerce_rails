require "rails_helper"

# Bước 6 — hàm thuần: KHÔNG cần database, chạy tức thì.
RSpec.describe Pricing::Calculator do
  let(:lines) { [{ unit_price: BigDecimal("100000"), quantity: 2 }] }

  it "cộng tiền hàng + phí ship nội địa" do
    r = described_class.call(lines: lines, shipping: Shipping::Domestic.new)
    expect([r.subtotal, r.shipping, r.total]).to eq([200_000, 20_000, 220_000].map { |n| BigDecimal(n) })
  end

  it "miễn phí ship nội địa từ 500.000" do
    big = [{ unit_price: BigDecimal("250000"), quantity: 2 }]
    expect(described_class.call(lines: big, shipping: Shipping::Domestic.new).shipping).to eq(0)
  end

  it "tính ship quốc tế bằng strategy khác" do
    r = described_class.call(lines: lines, shipping: Shipping::International.new)
    expect(r.shipping).to eq(BigDecimal("154000")) # 150.000 + 2% của 200.000
  end

  it "giảm giá không vượt quá tiền hàng và tổng không âm" do
    r = described_class.call(lines: lines, shipping: ->(_) { 0 }, discount: BigDecimal("999999"))
    expect(r.discount).to eq(200_000)
    expect(r.total).to eq(0)
  end

  it "dùng BigDecimal nên không dính sai số Float" do
    tiny = [{ unit_price: BigDecimal("0.1"), quantity: 3 }]
    expect(described_class.call(lines: tiny, shipping: ->(_) { 0 }).subtotal).to eq(BigDecimal("0.3"))
  end
end
