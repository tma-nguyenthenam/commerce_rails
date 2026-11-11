require "rails_helper"

# Bước 4 — thanh toán 3 pha. Gateway là ranh giới KHÔNG thuộc quyền sở hữu nên ta
# dùng double cho nó; còn database là THẬT.
RSpec.describe Orders::Pay do
  let(:order) { create(:order, status: "pending", total: 220_000) }
  let(:gateway) { instance_double(Payments::FakeGateway) }
  let(:charge) { Payments::FakeGateway::Response.new(success: true, external_id: "pay_123") }

  it "thanh toán thành công: ghi Payment và chuyển sang paid" do
    allow(gateway).to receive(:charge).and_return(charge)

    result = described_class.call(order.id, gateway: gateway)

    expect(result).to be_success
    expect(order.reload.status).to eq("paid")
    expect(order.payments.pluck(:external_id)).to eq(["pay_123"])
  end

  it "gọi lần hai trả :already_paid và gateway chỉ bị gọi MỘT lần" do
    allow(gateway).to receive(:charge).and_return(charge)

    described_class.call(order.id, gateway: gateway)
    second = described_class.call(order.id, gateway: gateway)

    expect(second.error).to eq(:already_paid)
    expect(gateway).to have_received(:charge).once
  end

  it "đơn đang payment_pending bị từ chối (request khác đang xử lý)" do
    order.update!(status: "payment_pending")

    expect(described_class.call(order.id, gateway: gateway).error).to eq(:payment_in_progress)
  end

  it "gateway timeout: đơn chuyển payment_failed và thử lại được" do
    calls = 0
    allow(gateway).to receive(:charge) do
      calls += 1
      raise Payments::GatewayTimeout if calls == 1

      charge
    end

    first = described_class.call(order.id, gateway: gateway)
    expect(first.error).to eq(:gateway_error)
    expect(order.reload.status).to eq("payment_failed")

    second = described_class.call(order.id, gateway: gateway)
    expect(second).to be_success
    expect(order.reload.status).to eq("paid")
  end

  it "luôn gửi idempotency_key cố định theo đơn để retry không bị tính tiền hai lần" do
    allow(gateway).to receive(:charge).and_return(charge)

    described_class.call(order.id, gateway: gateway)

    expect(gateway).to have_received(:charge).with(amount: order.total, idempotency_key: "order-#{order.id}")
  end

  it "KHÔNG giữ transaction mở khi gọi gateway (pha 2 nằm ngoài transaction)" do
    open_during_charge = nil
    allow(gateway).to receive(:charge) do
      open_during_charge = ActiveRecord::Base.connection.open_transactions
      charge
    end

    described_class.call(order.id, gateway: gateway)

    # Test chạy bên trong 1 transaction của rspec (=1). Nếu service giữ thêm transaction
    # thật thì con số sẽ lớn hơn 1.
    expect(open_during_charge).to eq(1)
  end

  it "trả :not_found với đơn không tồn tại" do
    expect(described_class.call(0, gateway: gateway).error).to eq(:not_found)
  end
end
