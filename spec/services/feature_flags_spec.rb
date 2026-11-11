require "rails_helper"

# Bước 10 — method_missing + respond_to_missing? (Q1)
RSpec.describe FeatureFlags do
  [FeatureFlags::Dynamic, FeatureFlags::Defined].each do |klass|
    describe klass do
      let(:flags) { klass.new(new_checkout: true, beta_ui: false) }

      it "đọc flag bằng method" do
        expect(flags.new_checkout).to be(true)
        expect(flags.beta_ui?).to be(false)
      end

      it "respond_to? trả lời đúng" do
        expect(flags).to respond_to(:new_checkout?)
        expect(flags).not_to respond_to(:khong_co)
      end

      it "lấy được Method object" do
        expect(flags.method(:new_checkout).call).to be(true)
      end
    end
  end

  it "Dynamic: tên sai ném NoMethodError, không bị nuốt thành nil" do
    flags = FeatureFlags::Dynamic.new(new_checkout: true)
    expect { flags.new_chekout }.to raise_error(NoMethodError) # gõ nhầm tên
  end

  it "Dynamic dùng method_missing nằm trong module (thấy ở ancestors)" do
    expect(FeatureFlags::Dynamic.ancestors).to include(FeatureFlags::Reader)
    expect(FeatureFlags::Dynamic.instance_methods(false)).not_to include(:new_checkout)
  end
end
