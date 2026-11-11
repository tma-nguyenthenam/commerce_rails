# Dữ liệu mẫu để xem trên giao diện. Chạy lại an toàn (idempotent).
users = [["an@example.com", "Nguyễn An"], ["binh@example.com", "Trần Bình"]].map do |email, name|
  User.find_or_create_by!(email: email) { |u| u.name = name }
end

[["Áo thun", 150_000, 10], ["Quần jean", 450_000, 3], ["Giày chạy bộ", 1_200_000, 1], ["Mũ lưỡi trai", 90_000, 0]].each do |name, price, stock|
  Product.find_or_create_by!(name: name) { |p| p.title = name; p.price = price; p.stock = stock }
end

if Order.none?
  ao, jean = Product.find_by!(title: "Áo thun"), Product.find_by!(title: "Quần jean")
  order = Order.create!(user: users[0], idempotency_key: "seed-1", status: "paid",
                        total: ao.price * 2 + jean.price, confirmation_sent_at: Time.current)
  order.items.create!(product: ao, quantity: 2, unit_price: ao.price)
  order.items.create!(product: jean, quantity: 1, unit_price: jean.price)
  order.payments.create!(status: "paid", external_id: "pay_seed_1", amount: order.total)

  Order.create!(user: users[1], idempotency_key: "seed-2", status: "pending", total: 0)
end

# Mã giảm giá để thử: giảm 50.000đ, dùng tối đa 3 lần
DiscountCode.find_or_create_by!(code: "SALE50") { |d| d.amount = 50_000; d.max_uses = 3 }
