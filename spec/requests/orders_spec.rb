require "rails_helper"

# Kiểm tra giao diện MVC gọi đúng use case.
RSpec.describe "Orders UI", type: :request do
  let!(:user) { create(:user) }
  let!(:product) { create(:product, stock: 5) }

  it "đặt hàng qua form, bấm đúp (cùng key) chỉ tạo một đơn" do
    params = { idempotency_key: "form-key", items: { product.id.to_s => "1" } }

    post orders_path, params: params
    expect(response).to redirect_to(order_path(Order.last))
    post orders_path, params: params # bấm đúp / refresh

    expect(Order.count).to eq(1)
    expect(product.reload.stock).to eq(4)
  end

  it "hiện lỗi thân thiện khi không đủ hàng" do
    post orders_path, params: { idempotency_key: "k", items: { product.id.to_s => "99" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("không đủ hàng")
  end

  it "các trang chính render được" do
    get root_path
    expect(response).to have_http_status(:ok)
    get new_order_path
    expect(response).to have_http_status(:ok)
  end
end
