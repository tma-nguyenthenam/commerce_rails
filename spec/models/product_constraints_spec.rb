require "rails_helper"

# Smoke test: xác nhận app nối được PostgreSQL và DB constraint hoạt động
RSpec.describe "Database constraints" do
  it "chặn stock âm ở tầng database, bỏ qua validation của model" do
    product = Product.create!(name: "Áo", price: 100_000, stock: 1)

    expect {
      product.update_column(:stock, -1)   # update_column không chạy validation
    }.to raise_error(ActiveRecord::StatementInvalid, /products_stock_non_negative/)
  end

  it "chặn idempotency_key trùng bằng unique index" do
    user = User.create!(email: "a@b.com", name: "A")
    Order.create!(user: user, idempotency_key: "k1")

    expect {
      Order.new(user: user, idempotency_key: "k1").save!(validate: false)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
