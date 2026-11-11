class Payment < ApplicationRecord
  belongs_to :order
  validates :amount, numericality: { greater_than: 0 }
end
