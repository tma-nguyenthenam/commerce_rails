class Payment < ActiveRecord::Base
  self.table_name = "payments"

  validates :idempotency_key, presence: true, uniqueness: true
  validates :amount, numericality: { greater_than: 0 }
end
