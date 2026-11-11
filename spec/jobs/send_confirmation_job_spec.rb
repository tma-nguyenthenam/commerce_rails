require "rails_helper"

# Bước 3 — job idempotent: chạy hai lần vẫn chỉ một email; lỗi thì retry được.
RSpec.describe SendConfirmationJob do
  let(:order) do
    o = create(:order)
    o.items.create!(product: create(:product), quantity: 1, unit_price: 100_000)
    o
  end

  before { ActionMailer::Base.deliveries.clear }

  it "chạy hai lần chỉ gửi MỘT email" do
    2.times { described_class.perform_now(order.id) }

    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(order.reload.confirmation_sent_at).to be_present
  end

  it "nhả claim khi gửi lỗi, để lần retry gửi lại được" do
    failing = instance_double(ActionMailer::MessageDelivery)
    allow(failing).to receive(:deliver_now).and_raise(Net::OpenTimeout)
    allow(OrderMailer).to receive(:confirmation).and_return(failing)

    # `retry_on` bắt Net::OpenTimeout và tự xếp lịch chạy lại, nên perform_now không raise.
    expect { described_class.perform_now(order.id) }.to have_enqueued_job(described_class)
    expect(order.reload.confirmation_sent_at).to be_nil # đã nhả, chưa bị coi là "đã gửi"

    allow(OrderMailer).to receive(:confirmation).and_call_original # lần retry mạng đã ổn
    described_class.perform_now(order.id)

    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(order.reload.confirmation_sent_at).to be_present
  end
end
