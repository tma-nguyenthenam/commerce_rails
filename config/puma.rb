# ════════════════════════════════════════════════════════════════════════════
# Cấu hình Puma (Bước 9, Q3). Ba con số phải tính CÙNG NHAU:
#
#   WEB_CONCURRENCY  : số worker = số PROCESS. Mỗi process có GVL riêng nên chạy
#                      Ruby song song được trên nhiều CPU core. Tốn RAM (mỗi cái
#                      chiếm hàng trăm MB).
#   RAILS_MAX_THREADS: số thread mỗi worker. Hữu ích cho việc chờ I/O (GVL được nhả
#                      khi chờ DB/HTTP), vô ích cho việc tính toán CPU thuần Ruby.
#   pool (database.yml): mỗi thread đang xử lý request cần 1 DB connection.
#
#   Tổng connection tối đa mỗi server = WEB_CONCURRENCY x RAILS_MAX_THREADS
#   (và pool phải >= RAILS_MAX_THREADS, nếu không sẽ gặp ConnectionTimeoutError).
#
# Thử nghiệm: WEB_CONCURRENCY=2 RAILS_MAX_THREADS=5 RAILS_ENV=production bin/rails s
# ════════════════════════════════════════════════════════════════════════════
max_threads = ENV.fetch("RAILS_MAX_THREADS", 3).to_i
threads max_threads, max_threads

workers ENV.fetch("WEB_CONCURRENCY", 0).to_i # 0 = một process duy nhất (chế độ single)
preload_app! if ENV.fetch("WEB_CONCURRENCY", 0).to_i.positive? # chia sẻ bộ nhớ giữa worker (copy-on-write)

# Mỗi worker (process con) phải tự mở lại kết nối DB sau khi fork.
on_worker_boot { ActiveRecord::Base.establish_connection } if ENV.fetch("WEB_CONCURRENCY", 0).to_i.positive?

port ENV.fetch("PORT", 3000)
plugin :tmp_restart
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
