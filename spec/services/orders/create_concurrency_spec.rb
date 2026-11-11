require "rails_helper"

# Bước 2 — test đồng thời THẬT: nhiều thread, mỗi thread một connection database.
#
# Phải TẮT transactional tests: mặc định mỗi test bọc trong một transaction chưa
# commit, các thread khác sẽ không thấy dữ liệu và còn dùng chung một connection.
# Đổi lại, ta phải tự dọn dữ liệu sau mỗi test.
RSpec.describe Orders::Create, "đồng thời" do
  self.use_transactional_tests = false

  # Giữ 4 thread + connection của test < pool mặc định (5)
  THREADS = 4

  after do
    [OrderItem, Payment, Order, DiscountCode, Product, User].each(&:delete_all)
  end

  # Chạy `count` thread cùng lúc, thread nào cũng đợi hiệu lệnh xuất phát để thật sự
  # va chạm nhau; mỗi thread tự mượn/trả connection.
  def run_concurrently(count)
    start = Queue.new
    threads = Array.new(count) do |i|
      Thread.new do
        start.pop # chờ hiệu lệnh
        ActiveRecord::Base.connection_pool.with_connection { yield(i) }
      end
    end
    count.times { start << :go }
    threads.map(&:value)
  end

  it "món cuối cùng chỉ bán được cho đúng một người" do
    user = create(:user)
    product = create(:product, stock: 1)

    results = run_concurrently(THREADS) do |i|
      described_class.call(user: user, items: [{ product_id: product.id, quantity: 1 }], idempotency_key: "k-#{i}")
    end

    expect(results.count(&:success?)).to eq(1)
    expect(results.reject(&:success?).map(&:error).uniq).to eq([:insufficient_stock])
    expect(product.reload.stock).to eq(0)
    expect(Order.count).to eq(1)
  end

  it "cùng idempotency key gửi đồng thời chỉ tạo một đơn và trừ kho một lần" do
    user = create(:user)
    product = create(:product, stock: 10)

    results = run_concurrently(THREADS) do
      described_class.call(user: user, items: [{ product_id: product.id, quantity: 1 }], idempotency_key: "same-key")
    end

    expect(results).to all(be_success)
    expect(results.map { |r| r.order.id }.uniq.size).to eq(1)
    expect(Order.count).to eq(1)
    expect(product.reload.stock).to eq(9)
  end

  it "mã giảm giá max_uses = 1 chỉ dùng được một lần khi đồng thời" do
    user = create(:user)
    product = create(:product, stock: 10)
    create(:discount_code, code: "ONE", max_uses: 1)

    results = run_concurrently(THREADS) do |i|
      described_class.call(user: user, items: [{ product_id: product.id, quantity: 1 }],
                           idempotency_key: "d-#{i}", discount_code: "ONE")
    end

    expect(results.count(&:success?)).to eq(1)
    expect(DiscountCode.find_by(code: "ONE").used_count).to eq(1)
    expect(Order.count).to eq(1)
    expect(product.reload.stock).to eq(9) # các đơn thất bại đã hoàn kho
  end
end
