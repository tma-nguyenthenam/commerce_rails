require "rails_helper"

# Bước 7 — cache theo version key.
RSpec.describe Catalog::ProductsList do
  let(:store) { ActiveSupport::Cache::MemoryStore.new }

  before { allow(Rails).to receive(:cache).and_return(store) } # môi trường test mặc định là null_store

  it "lần hai lấy từ cache, không truy vấn lại danh sách" do
    create(:product)
    described_class.call

    expect(Product).not_to receive(:order)
    described_class.call
  end

  it "sản phẩm cập nhật thì key đổi và cache tự làm mới" do
    product = create(:product, title: "Cũ")
    described_class.call

    product.update!(title: "Mới", updated_at: 1.minute.from_now)

    expect(described_class.call.map { |r| r[:title] }).to eq(["Mới"])
  end

  it "GIỚI HẠN ĐÃ BIẾT: update_all không đổi updated_at nên cache bị cũ" do
    product = create(:product, stock: 10)
    described_class.call

    Product.where(id: product.id).update_all(stock: 0) # bỏ qua updated_at

    expect(described_class.call.first[:stock]).to eq(10) # vẫn là số cũ
  end

  it "khi cache hỏng vẫn trả dữ liệu từ database" do
    create(:product, title: "A")
    allow(store).to receive(:fetch).and_raise(StandardError, "redis down")

    expect(described_class.call.map { |r| r[:title] }).to eq(["A"])
  end
end
