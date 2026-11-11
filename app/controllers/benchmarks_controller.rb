# ════════════════════════════════════════════════════════════════════════════
# Bước 9 — endpoint để load test Puma (Q3: GVL). CHỈ DÙNG ĐỂ HỌC, xóa khỏi app thật.
#
#   /benchmark/io  : chờ 0.2 giây (giả lập gọi API ngoài). GVL được NHẢ khi sleep,
#                    nên nhiều thread xử lý đồng thời được -> tăng threads có ích.
#   /benchmark/cpu : tính toán Ruby thuần. GVL bị GIỮ suốt lúc tính, nên thêm thread
#                    KHÔNG giúp gì; muốn nhanh hơn phải thêm worker (process).
# ════════════════════════════════════════════════════════════════════════════
class BenchmarksController < ApplicationController
  def io
    sleep 0.2
    render plain: "io ok"
  end

  def cpu
    result = (1..300_000).sum { |i| Math.sqrt(i) * Math.sin(i) }
    render plain: "cpu ok #{result.round(2)}"
  end

  # Truy vấn DB: mỗi request giữ một connection -> dùng để thấy ConnectionTimeoutError
  # khi pool < số thread.
  def db
    Product.connection.execute("SELECT pg_sleep(0.1)")
    render plain: "db ok"
  end
end
