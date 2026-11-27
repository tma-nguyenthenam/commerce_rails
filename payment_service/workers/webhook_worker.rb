# Tạo Webhook Worker có nhiệm vụ:
# 1. Tìm webhook có trạng thái pending.
# 2. Chuyển trạng thái sang processing.
# 3. Gọi WebhookEventHandler để xử lý.
# 4. Thành công → processed.
# 5. Thất bại → failed, tăng attempts và lưu lỗi.

require_relative "../models/webhook_event"
require_relative "../services/webhook_event_handler"
require_relative "../services/rails_webhook_notifier"

module Webhooks
  class WebhookWorker
    def initialize(
        handler: WebhookEventHandler.new,
        notifier: RailsWebhookNotifier.new
        )
        @handler = handler
        @notifier = notifier
    end

    
    def perform_once
        event = claim_event
        return false unless event

        puts "[WebhookWorker] Processing event: #{event.event_id}"
        puts "[WebhookWorker] Event type: #{event.event_type}"

        process(event)
        true
        end

    private

    def claim_event
        WebhookEvent.transaction do
            event = WebhookEvent
            .where(status: "pending")
            .order(:id)
            .lock("FOR UPDATE SKIP LOCKED")
            .first

            if event
            event.update!(
                status: "processing",
                attempts: event.attempts + 1
            )
            end

            event
        end
    end

    def process(event)
        puts "[WebhookWorker] Processing event: #{event.event_id}"
        puts "[WebhookWorker] Event type: #{event.event_type}"

        @handler.call(event)
        puts "[WebhookWorker] Payment updated successfully"

        @notifier.call(event)
        puts "[WebhookWorker] Rails webhook delivered successfully"

        event.update!(
            status: "processed",
            processed_at: Time.now,
            last_error: nil
        )

        puts "[WebhookWorker] Event processed: #{event.event_id}"

        rescue StandardError => e
        event.update!(
            status: "failed",
            last_error: "#{e.class}: #{e.message}"
        )

        warn "[WebhookWorker] Event #{event.event_id} failed: #{e.class} - #{e.message}"
        end

    end
end
