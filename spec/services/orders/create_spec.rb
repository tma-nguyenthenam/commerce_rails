require "rails_helper"

# Bước 1 — các test bắt buộc của lab: thành công, sản phẩm sai, thiếu hàng,
# idempotency key trùng, rollback, và job chỉ xếp hàng sau commit.
RSpec.describe Orders::Create do
  let(:user) { create(:user) }
  let!(:product) { create(:product, price: 100_000, stock: 5) }

  def call(items: [{ product_id: product.id, quantity: 2 }], key: "key-1", **extra)
    described_class.call(user: user, items: items, idempotency_key: key, request_id: "req-1", **extra)
  end

  it "tạo đơn thành công, trừ kho và tính tiền bằng BigDecimal" do
    result = call

    expect(result).to be_success
    order = result.order
    expect(order.items.count).to eq(1)
    expect(order.items.first.unit_price).to eq(BigDecimal("100000"))
    # 2 x 100.000 = 200.000 (chưa đủ 500.000 nên phí ship 20.000)
    expect(order.total).to eq(BigDecimal("220000"))
    expect(product.reload.stock).to eq(3)
  end

  it "trả :invalid_product khi sản phẩm không tồn tại và không tạo gì cả" do
    result = call(items: [{ product_id: 0, quantity: 1 }])

    expect(result).to be_failure
    expect(result.error).to eq(:invalid_product)
    expect(Order.count).to eq(0)
  end

  it "trả :invalid_items khi số lượng <= 0 hoặc rỗng" do
    expect(call(items: []).error).to eq(:invalid_items)
    expect(call(items: [{ product_id: product.id, quantity: 0 }]).error).to eq(:invalid_items)
    expect(call(items: [{ product_id: product.id, quantity: "abc" }]).error).to eq(:invalid_items)
  end

  it "trả :insufficient_stock khi không đủ hàng, tồn kho không đổi" do
    result = call(items: [{ product_id: product.id, quantity: 6 }])

    expect(result.error).to eq(:insufficient_stock)
    expect(product.reload.stock).to eq(5)
    expect(Order.count).to eq(0)
  end

  it "idempotency key trùng: trả lại đơn cũ, không tạo đơn mới, không trừ kho lần hai" do
    first = call
    second = call

    expect(second).to be_success
    expect(second).to be_replayed
    expect(second.order.id).to eq(first.order.id)
    expect(Order.count).to eq(1)
    expect(product.reload.stock).to eq(3) # chỉ trừ một lần
  end

  it "rollback toàn bộ khi một dòng hàng thất bại giữa chừng" do
    sold_out = create(:product, stock: 0)

    result = call(items: [{ product_id: product.id, quantity: 1 }, { product_id: sold_out.id, quantity: 1 }])

    expect(result.error).to eq(:insufficient_stock)
    expect(Order.count).to eq(0)
    expect(OrderItem.count).to eq(0)
    expect(product.reload.stock).to eq(5) # phần trừ kho của dòng đầu cũng được hoàn lại
  end

  it "gộp các dòng trùng product_id" do
    result = call(items: [{ product_id: product.id, quantity: 1 }, { product_id: product.id, quantity: 2 }])

    expect(result.order.items.sum(:quantity)).to eq(3)
    expect(product.reload.stock).to eq(2)
  end

  describe "job xác nhận (chỉ sau commit)" do
    it "xếp hàng job khi thành công" do
      expect { call }.to have_enqueued_job(SendConfirmationJob)
    end

    it "KHÔNG xếp hàng job khi transaction rollback" do
      expect { call(items: [{ product_id: product.id, quantity: 99 }]) }
        .not_to have_enqueued_job(SendConfirmationJob)
    end

    it "KHÔNG xếp hàng job lần nữa khi phát lại cùng key" do
      call
      expect { call }.not_to have_enqueued_job(SendConfirmationJob)
    end
  end

  describe "mã giảm giá" do
    it "áp dụng giảm giá và tăng lượt dùng" do
      create(:discount_code, code: "SALE50", amount: 50_000, max_uses: 1)

      result = call(discount_code: "SALE50")

      expect(result.order.total).to eq(BigDecimal("170000")) # 200.000 + 20.000 ship - 50.000
      expect(DiscountCode.find_by(code: "SALE50").used_count).to eq(1)
    end

    it "từ chối mã đã hết lượt và rollback cả đơn" do
      create(:discount_code, code: "ONCE", max_uses: 1, used_count: 1)

      result = call(discount_code: "ONCE")

      expect(result.error).to eq(:invalid_discount)
      expect(Order.count).to eq(0)
      expect(product.reload.stock).to eq(5)
    end
  end
end
