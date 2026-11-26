# Khi nhận payment.succeeded, Handler sẽ:
# 1. Tìm Payment bằng external_id.
# 2. Kiểm tra order_id có khớp không.
# 3. Kiểm tra amount có khớp không.
# 4. Nếu Payment đang pending, chuyển thành paid.
# 5. Nếu Payment đã paid, không cập nhật lại.

require_relative "../models/payment"
module Webhooks
  class WebhookEventHandler
    def call(event)
      data = event.payload.fetch("data")

      case event.event_type
      when "payment.succeeded"
        update_payment(data, "paid")
      when "payment.failed"
        update_payment(data, "failed")
      else
        raise ArgumentError, "Unsupported event type: #{event.event_type}"
      end
    end

    private

    def update_payment(data, new_status)
        Payment.transaction do
            payment = Payment.lock.find_by!(
            external_id: data.fetch("external_id")
            )

            unless payment.order_id == data.fetch("order_id")
            raise ArgumentError, "order_id_mismatch"
            end

            unless payment.amount == BigDecimal(data.fetch("amount").to_s)
            raise ArgumentError, "amount_mismatch"
            end

            if payment.status == "paid"
            puts "[Webhook] Payment already paid: #{payment.external_id}"
            :already_paid

            elsif payment.status == "pending"
            payment.update!(status: new_status)

            puts "[Webhook] Payment updated"
            puts "External ID: #{payment.external_id}"
            puts "Status: #{payment.status}"

            :updated

            else
            raise ArgumentError, "invalid_payment_status: #{payment.status}"
            end
        end
    end
  end
end
