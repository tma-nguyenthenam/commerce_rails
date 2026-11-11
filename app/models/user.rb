class User < ApplicationRecord
  has_many :orders, dependent: :restrict_with_error

  validates :email, :name, presence: true
  validates :email, uniqueness: true
end
