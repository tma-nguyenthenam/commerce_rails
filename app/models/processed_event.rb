class ProcessedEvent < ApplicationRecord
  validates :external_event_id, presence: true
end
