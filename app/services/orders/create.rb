# frozen_string_literal: true

module Orders
  # ════════════════════════════════════════════════════════════════════════════
  # Orders::Create — use case "đặt hàng" (lab chính của tuần 1)
  #
  # Câu hỏi phỏng vấn liên quan: Q4 (transaction), Q5 (idempotency), Q6 (after_commit),
  # Q8 (tách service), Q10 (typed result).
  #
  # Service này là CHỦ SỞ HỮU của transaction: một thao tác nghiệp vụ trọn vẹn
  # ("tạo đơn + các dòng hàng + trừ kho + dùng mã giảm giá") hoặc thành công hết,
  # hoặc rollback hết.
  #
  # Cách dùng:
  #   result = Orders::Create.call(
  #     user: user,
  #     items: [{ product_id: 1, quantity: 2 }],
  #     idempotency_key: "uuid-từ-client",
  #     request_id: request.request_id,     # để ghi log
  #     discount_code: "SALE50"             # tùy chọn
  #   )
  # ════════════════════════════════════════════════════════════════════════════
  class Create
    # Các lỗi NỘI BỘ: dùng để dừng + rollback transaction, rồi được chuyển thành
    # Result.failure ở cuối `call`. Chúng không bao giờ lọt ra ngoài service.
    class InvalidProduct < StandardError; end
    class OutOfStock < StandardError; end

    def self.call(**args) = new.call(**args)

    def initialize(logger: Rails.logger, shipping: Shipping::Domestic.new)
      @logger = logger
      @shipping = shipping
    end

    def call(user:, items:, idempotency_key:, request_id: nil, discount_code: nil)
      # ── 1. Validate đầu vào (rẻ, làm trước khi đụng database) ────────────────
      lines = normalize_items(items)
      return Result.failure(:invalid_items) if lines.nil?
      return Result.failure(:missing_idempotency_key) if idempotency_key.blank?

      # ── 2. Idempotency, đường nhanh ──────────────────────────────────────────
      # Client retry (mạng chập chờn, bấm đúp nút) với cùng key -> trả lại đơn cũ,
      # không tạo đơn thứ hai. Đây chỉ là tối ưu + thông báo đẹp: người bảo vệ
      # thật sự là UNIQUE INDEX trên orders.idempotency_key (xem rescue bên dưới).
      if (existing = Order.find_by(idempotency_key: idempotency_key))
        return Result.success(existing, replayed: true)
      end

      # ── 3. Transaction: tất cả hoặc không gì cả ──────────────────────────────
      order = Order.transaction do
        build_order!(user: user, lines: lines, idempotency_key: idempotency_key, discount_code: discount_code)
      end

      # ── 4. Việc phụ chỉ chạy SAU KHI transaction đã commit (Q6) ──────────────
      # Nếu enqueue trong transaction: job có thể chạy trước commit (không thấy
      # đơn), hoặc transaction rollback mà email vẫn gửi đi. Ở đây dòng này nằm
      # NGOÀI khối transaction nên chỉ chạy khi đơn đã thực sự được lưu.
      SendConfirmationJob.perform_later(order.id)

      log("order.created", order_id: order.id, request_id: request_id, total: order.total.to_s)
      Result.success(order)
    rescue InvalidProduct
      log("order.rejected", reason: :invalid_product, request_id: request_id)
      Result.failure(:invalid_product)
    rescue OutOfStock
      log("order.rejected", reason: :insufficient_stock, request_id: request_id)
      Result.failure(:insufficient_stock)
    rescue DiscountCode::Exhausted
      log("order.rejected", reason: :invalid_discount, request_id: request_id)
      Result.failure(:invalid_discount)
    rescue ActiveRecord::RecordNotUnique
      # Hai request CÙNG key chạy ĐỒNG THỜI: cả hai đều qua bước 2 (chưa ai commit).
      # Unique index cho một bên thắng; bên thua vào đây. Transaction của bên thua
      # đã rollback (kể cả phần trừ kho). Ta trả về đơn của bên thắng.
      winner = Order.find_by(idempotency_key: idempotency_key)
      raise unless winner # lỗi unique khác, không phải do idempotency -> không nuốt

      log("order.replayed", order_id: winner.id, request_id: request_id)
      Result.success(winner, replayed: true)
    end

    private

    # Chuẩn hóa items: gộp dòng trùng product_id, ép kiểu, kiểm tra số lượng > 0.
    # Trả về mảng [{product_id:, quantity:}] SẮP XẾP theo product_id, hoặc nil nếu sai.
    #
    # Vì sao sắp xếp? Khi 2 đơn cùng mua sản phẩm A và B, nếu đơn 1 khóa A rồi B còn
    # đơn 2 khóa B rồi A thì sẽ DEADLOCK. Luôn khóa theo cùng một thứ tự (id tăng dần)
    # thì không thể xảy ra vòng chờ.
    def normalize_items(items)
      return nil unless items.is_a?(Array) && items.any?

      merged = Hash.new(0)
      items.each do |item|
        product_id = Integer(item[:product_id], exception: false)
        quantity = Integer(item[:quantity], exception: false)
        return nil if product_id.nil? || quantity.nil? || quantity <= 0

        merged[product_id] += quantity
      end
      merged.sort.map { |product_id, quantity| { product_id: product_id, quantity: quantity } }
    end

    def build_order!(user:, lines:, idempotency_key:, discount_code:)
      products = Product.where(id: lines.map { |l| l[:product_id] }).index_by(&:id)
      raise InvalidProduct if products.size != lines.size

      # Tạo order TRƯỚC. Nếu hai request cùng key chạy song song, bên thứ hai sẽ bị
      # chặn ở unique index ngay tại đây, trước cả khi trừ kho.
      order = Order.create!(user: user, idempotency_key: idempotency_key, status: "pending", total: 0)

      priced_lines = lines.map do |line|
        product = products.fetch(line[:product_id])
        reserve_stock!(product, line[:quantity])
        order.items.create!(product: product, quantity: line[:quantity], unit_price: product.price.to_d)
        { unit_price: product.price.to_d, quantity: line[:quantity] }
      end

      discount = discount_code.present? ? DiscountCode.redeem!(discount_code).amount : BigDecimal("0")
      breakdown = Pricing::Calculator.call(lines: priced_lines, shipping: @shipping, discount: discount)
      order.update!(total: breakdown.total)
      order
    end

    # ── Chống oversell (Q4) ───────────────────────────────────────────────────
    # KHÔNG làm kiểu "đọc rồi ghi":
    #     product.stock -= qty; product.save!   # 2 request cùng thấy stock = 1 -> bán 2 lần
    #
    # Làm MỘT câu UPDATE có điều kiện, để PostgreSQL tự kiểm tra và trừ nguyên tử:
    #     UPDATE products SET stock = stock - 2 WHERE id = 7 AND stock >= 2
    # PostgreSQL khóa dòng khi UPDATE, nên request thứ hai phải đợi request thứ nhất
    # commit rồi đánh giá lại điều kiện `stock >= 2` với giá trị MỚI -> 0 dòng -> hết hàng.
    #
    # Ta cũng cập nhật updated_at vì update_all bỏ qua timestamp tự động; nếu không,
    # cache danh sách sản phẩm (Catalog) sẽ không biết tồn kho đã đổi (bước 7).
    def reserve_stock!(product, quantity)
      updated = Product.where(id: product.id)
                       .where("stock >= ?", quantity)
                       .update_all(["stock = stock - ?, updated_at = ?", quantity, Time.current])
      raise OutOfStock if updated.zero?
    end

    # Structured log: một dòng JSON, dễ lọc theo request_id/order_id trong hệ thống log.
    def log(event, **fields)
      @logger.info({ event: event }.merge(fields).to_json)
    end
  end
end
