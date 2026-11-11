FactoryBot.define do
  factory :product do
    sequence(:title) { |n| "Sản phẩm #{n}" }
    price { BigDecimal("100000") }
    stock { 10 }
  end
end
