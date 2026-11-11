# frozen_string_literal: true

# ════════════════════════════════════════════════════════════════════════════
# SendConfirmationJob — job idempotent (Q5)
#
# Hệ thống queue thường là "at-least-once": job CÓ THỂ chạy 2 lần (worker chết giữa
# chừng, retry, deploy). Job phải cho cùng kết quả dù chạy bao nhiêu lần:
# khách chỉ nhận ĐÚNG MỘT email.
#
# Quy tắc áp dụng:
#   1. Nhận ID (order_id), không nhận object: object có thể đã cũ khi job chạy.
#   2. "Chiếm việc" bằng MỘT câu UPDATE có điều kiện (nguyên tử):
#        UPDATE orders SET confirmation_sent_at = now()
#        WHERE id = ? AND confirmation_sent_at IS NULL
#      Chỉ một lần chạy nhận được "1 dòng bị ảnh hưởng"; các lần khác nhận 0 và dừng.
#   3. Nếu gửi thất bại thì NHẢ lại "claim" rồi raise, để lần retry gửi lại được.
# ════════════════════════════════════════════════════════════════════════════
class SendConfirmationJob < ApplicationJob
  queue_as :default

  # Lỗi mạng tạm thời -> tự retry, giãn cách tăng dần.
  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 5

  def perform(order_id)
    claimed = Order.where(id: order_id, confirmation_sent_at: nil)
                   .update_all(confirmation_sent_at: Time.current)
    return if claimed.zero? # lần chạy khác đã gửi (hoặc đang gửi) rồi

    begin
      OrderMailer.confirmation(Order.find(order_id)).deliver_now
    rescue StandardError
      # Gửi lỗi: trả lại trạng thái "chưa gửi" để retry không bị chặn nhầm.
      Order.where(id: order_id).update_all(confirmation_sent_at: nil)
      raise
    end
  end
end
