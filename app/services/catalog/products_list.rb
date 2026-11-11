# frozen_string_literal: true

module Catalog
  # ════════════════════════════════════════════════════════════════════════════
  # Cache danh sách sản phẩm (Q9: cache invalidation)
  #
  # Bước đầu tiên: xác định AI sở hữu dữ liệu và cần "tươi" đến mức nào.
  # Ở đây: bảng products là nguồn sự thật, danh sách có thể cũ vài phút nếu cần.
  #
  # Chiến lược: KEY THEO PHIÊN BẢN thay vì xóa cache bằng tay.
  #   key = ["catalog", số sản phẩm, updated_at mới nhất]
  # Sản phẩm đổi (updated_at mới) hoặc thêm/xóa (count đổi) -> key đổi -> lần sau tự
  # miss và dựng lại. Không cần nhớ chỗ nào phải gọi "xóa cache".
  # Thêm TTL ngắn làm lưới an toàn cho những thay đổi mà key không thấy.
  #
  # GIỚI HẠN ĐÃ BIẾT (nên nêu ra khi phỏng vấn):
  #   * `update_all` KHÔNG cập nhật updated_at -> key không đổi -> cache cũ.
  #     (Orders::Create đã tự ghi updated_at khi trừ kho để tránh lỗi này.)
  #   * Xóa một sản phẩm cũ nhất cùng lúc thêm một sản phẩm mới có thể trùng key; hiếm,
  #     và TTL sẽ tự sửa.
  # ════════════════════════════════════════════════════════════════════════════
  class ProductsList
    TTL = 5.minutes

    def self.call = new.call

    def call
      Rails.cache.fetch(cache_key, expires_in: TTL) { load_rows }
    rescue StandardError => e
      # Khi cache hỏng (Redis chết...): vẫn phải phục vụ được, chỉ chậm hơn.
      # Cache là tối ưu, không được phép làm sập trang.
      Rails.logger.warn({ event: "catalog.cache_unavailable", error: e.class.name }.to_json)
      load_rows
    end

    private

    def cache_key
      ["catalog", Product.count, Product.maximum(:updated_at)&.utc&.to_fs(:usec)]
    end

    # Cache dữ liệu thuần (Hash) thay vì object ActiveRecord: nhỏ hơn, ổn định hơn
    # khi serialize, và view không vô tình gọi thêm query.
    def load_rows
      Product.order(:id).map do |p|
        { id: p.id, title: p.title, price: p.price, stock: p.stock }
      end
    end
  end
end
