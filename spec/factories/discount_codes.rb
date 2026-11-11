FactoryBot.define do
  factory :discount_code do
    sequence(:code) { |n| "CODE#{n}" }
    amount { BigDecimal("50000") }
    max_uses { 3 }
  end
end
