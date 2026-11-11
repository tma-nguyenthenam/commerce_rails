# frozen_string_literal: true

module Orders
  # ── "Typed result" (yêu cầu của lab) ────────────────────────────────────────
  # Thay vì raise exception của ActiveRecord ra ngoài (RecordNotUnique,
  # StatementInvalid...), service luôn trả về một Result.
  # Controller chỉ cần hỏi `result.success?` rồi đọc `result.error` (một Symbol
  # có tên nghiệp vụ như :insufficient_stock) để quyết định hiển thị gì.
  #
  #   result = Orders::Create.call(...)
  #   result.success?  # => true/false
  #   result.order     # => Order (khi thành công, hoặc kèm theo khi thất bại nếu có)
  #   result.error     # => :invalid_product, :insufficient_stock, ...
  Result = Struct.new(:ok, :order, :error, :replayed, keyword_init: true) do
    def self.success(order, replayed: false) = new(ok: true, order: order, replayed: replayed)
    def self.failure(error, order: nil) = new(ok: false, error: error, order: order)

    def success? = ok
    def failure? = !ok

    # true khi request này chỉ "phát lại" kết quả của một request trước
    # (cùng idempotency_key) chứ không tạo đơn mới.
    def replayed? = replayed == true
  end
end
