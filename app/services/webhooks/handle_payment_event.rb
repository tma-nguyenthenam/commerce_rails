# frozen_string_literal: true

module Webhooks
  # ════════════════════════════════════════════════════════════════════════════
  # Xử lý webhook từ cổng thanh toán, an toàn khi gateway GỬI TRÙNG (Q5)
  #
  # Gateway thường gửi webhook "at-least-once": cùng một sự kiện có thể đến 2-3 lần.
  # Cách chống trùng: bảng processed_events có UNIQUE INDEX trên external_event_id.
  #
  # QUAN TRỌNG — thứ tự và transaction:
  #   1. Ghi ProcessedEvent TRƯỚC (nếu trùng, unique index ném RecordNotUnique -> dừng).
  #   2. Rồi mới áp dụng thay đổi cho đơn.
  #   3. Cả hai nằm TRONG MỘT transaction. Nếu bước 2 lỗi thì bước 1 cũng rollback,
  #      nên lần gửi lại sau đó vẫn được xử lý (không bị coi nhầm là "đã xử lý").
  #
  # Nếu ghi ProcessedEvent SAU khi áp dụng thay đổi: hai webhook đồng thời cùng áp
  # dụng thay đổi rồi mới đụng unique index -> thay đổi bị làm hai lần.
  # ════════════════════════════════════════════════════════════════════════════
  class HandlePaymentEvent
    ALLOWED_STATUSES = %w[paid payment_failed].freeze

    def self.call(**args) = new.call(**args)

    # Trả về Orders::Result để dùng chung kiểu kết quả với phần còn lại.
    def call(event_id:, order_id:, status:)
      return Orders::Result.failure(:invalid_event) if event_id.blank? || ALLOWED_STATUSES.exclude?(status)

      order = Order.transaction do
        ProcessedEvent.create!(external_event_id: event_id)
        Order.find(order_id).tap { |o| o.update!(status: status) }
      end
      Orders::Result.success(order)
    rescue ActiveRecord::RecordNotUnique
      # Đã xử lý sự kiện này rồi: báo thành công để gateway ngừng gửi lại.
      Orders::Result.success(Order.find_by(id: order_id), replayed: true)
    rescue ActiveRecord::RecordNotFound
      Orders::Result.failure(:order_not_found)
    end
  end
end
