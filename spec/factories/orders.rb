FactoryBot.define do
  factory :order do
    user
    status { "pending" }
    sequence(:idempotency_key) { |n| "key-#{n}" }
    total { BigDecimal("100000") }
  end
end
