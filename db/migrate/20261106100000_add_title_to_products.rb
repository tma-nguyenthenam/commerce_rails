# ════════════════════════════════════════════════════════════════════════════
# BƯỚC 8 — Đổi tên cột products.name -> products.title (zero-downtime, Q7)
#
# KHÔNG dùng `rename_column`: trong lúc deploy, code CŨ (đọc/ghi `name`) và code MỚI
# chạy cùng lúc. Đổi tên một phát là code cũ lỗi ngay.
#
# Quy trình expand-and-contract, mỗi bước là một lần deploy riêng:
#
#   RELEASE 1 (EXPAND)  ← file này: thêm cột `title` (cho phép NULL, không default
#                         nặng). Code ghi CẢ HAI cột (xem Product#sync_title_and_name).
#   RELEASE 2 (BACKFILL) rake products:backfill_title  — điền title cho dòng cũ, theo
#                         lô nhỏ, chạy lại được, có nghỉ giữa các lô.
#   RELEASE 3 (SWITCH READS) mọi chỗ đọc chuyển sang `title` (views đã làm).
#   RELEASE 4 (STOP WRITING) ngừng ghi `name` + `self.ignored_columns += ["name"]`.
#   RELEASE 5 (CONTRACT) xóa cột `name`: xem db/contract/*.pending (CHƯA chạy).
# ════════════════════════════════════════════════════════════════════════════
class AddTitleToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :title, :string
  end
end
