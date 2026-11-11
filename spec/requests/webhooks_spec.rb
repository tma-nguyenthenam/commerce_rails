require "rails_helper"

# Bước 5 — gateway gửi trùng cùng một webhook: chỉ xử lý một lần.
RSpec.describe "POST /webhooks/payments", type: :request do
  let(:order) { create(:order, status: "payment_pending") }
  let(:params) { { event_id: "evt_1", order_id: order.id, status: "paid" } }

  it "xử lý sự kiện lần đầu" do
    post "/webhooks/payments", params: params, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("ok" => true, "duplicate" => false)
    expect(order.reload.status).to eq("paid")
  end

  it "gửi trùng: cả hai đều 200 nhưng chỉ xử lý một lần" do
    post "/webhooks/payments", params: params, as: :json
    order.update!(status: "pending") # nếu bị xử lý lần hai thì sẽ quay lại "paid"
    post "/webhooks/payments", params: params, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["duplicate"]).to be(true)
    expect(order.reload.status).to eq("pending")
    expect(ProcessedEvent.where(external_event_id: "evt_1").count).to eq(1)
  end

  it "đơn không tồn tại: 404 và KHÔNG ghi ProcessedEvent (cùng transaction nên rollback)" do
    post "/webhooks/payments", params: params.merge(order_id: 0), as: :json

    expect(response).to have_http_status(:not_found)
    expect(ProcessedEvent.count).to eq(0) # lần gửi lại sau vẫn được xử lý
  end

  it "trạng thái không hợp lệ: 422" do
    post "/webhooks/payments", params: params.merge(status: "hacked"), as: :json

    expect(response).to have_http_status(:unprocessable_content)
  end
end
