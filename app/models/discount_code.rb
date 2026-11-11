class DiscountCode < ApplicationRecord
  class Exhausted < StandardError; end

  validates :code, presence: true, uniqueness: true
  validates :max_uses, numericality: { only_integer: true, greater_than: 0 }

  # ── Atomic update cho bộ đếm (Q4/Q5) ────────────────────────────────────────
  # SAI (race condition): đọc rồi ghi
  #     code = DiscountCode.find_by(code: x)
  #     code.update!(used_count: code.used_count + 1) if code.used_count < code.max_uses
  # Hai request cùng đọc used_count = 0 -> cả hai cùng qua -> dùng vượt giới hạn.
  #
  # ĐÚNG: để chính database kiểm tra và tăng trong MỘT câu lệnh.
  #     UPDATE discount_codes SET used_count = used_count + 1
  #     WHERE code = 'X' AND used_count < max_uses
  # Số dòng bị ảnh hưởng = 0 nghĩa là mã không tồn tại hoặc đã hết lượt.
  # (check constraint `used_count <= max_uses` là lớp bảo vệ cuối cùng.)
  def self.redeem!(code)
    updated = where(code: code)
              .where("used_count < max_uses")
              .update_all("used_count = used_count + 1")
    raise Exhausted, code if updated.zero?

    find_by!(code: code)
  end
end
