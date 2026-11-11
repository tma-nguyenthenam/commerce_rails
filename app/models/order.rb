class Order < ApplicationRecord
  STATUSES = %w[pending payment_pending paid payment_failed cancelled].freeze

  belongs_to :user
  has_many :items, class_name: "OrderItem", dependent: :destroy
  has_many :payments, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
  validates :idempotency_key, presence: true
end
