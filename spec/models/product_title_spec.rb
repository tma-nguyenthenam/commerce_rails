require "rails_helper"
require "rake"

# Bước 8 — giai đoạn dual-write: code cũ (name) và code mới (title) cùng chạy được.
RSpec.describe Product, "đổi tên cột name -> title" do
  it "code cũ chỉ ghi name -> title được điền theo" do
    product = Product.create!(name: "Áo", price: 1, stock: 1)
    expect(product.title).to eq("Áo")
  end

  it "code mới chỉ ghi title -> name được điền theo" do
    product = Product.create!(title: "Quần", price: 1, stock: 1)
    expect(product.name).to eq("Quần")
  end

  it "đổi title thì name đi theo" do
    product = create(:product, title: "A")
    product.update!(title: "B")
    expect(product.reload.name).to eq("B")
  end

  it "backfill chỉ điền các dòng thiếu title và chạy lại được" do
    old_row = create(:product)
    Product.where(id: old_row.id).update_all(title: nil, name: "Dòng cũ") # mô phỏng dòng có từ trước release 1
    Rails.application.load_tasks unless Rake::Task.task_defined?("products:backfill_title")

    2.times do
      Rake::Task["products:backfill_title"].reenable
      ENV["PAUSE"] = "0"
      Rake::Task["products:backfill_title"].invoke
    end

    expect(old_row.reload.title).to eq("Dòng cũ")
  end
end
