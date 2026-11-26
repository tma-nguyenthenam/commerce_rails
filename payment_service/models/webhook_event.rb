require "active_record"

class WebhookEvent < ActiveRecord::Base
  STATUSES = %w[
    pending
    processing
    processed
    failed
  ].freeze

  validates :event_id, presence: true, uniqueness: true
  validates :event_type, presence: true
  validates :payload, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :attempts, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0
  }
end
