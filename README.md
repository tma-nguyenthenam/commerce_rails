# Commerce API (Week 1 training)

Ruby 3.4.5 · Rails 8.0 (MVC, có view) · PostgreSQL 16 (Docker, cổng 5433) · RSpec

## Chạy lần đầu
```bash
docker compose up -d          # bật PostgreSQL
bundle install
bin/rails db:create db:migrate
bundle exec rspec
bin/rails db:seed             # dữ liệu mẫu
bin/rails server              # mở http://localhost:3000
```

Trang có sẵn: `/products`, `/products/:id`, `/orders`, `/orders/:id` (chỉ đọc).

## Kết nối DB
Mặc định: `localhost:5433`, user `commerce`, password `password`.
Ghi đè bằng biến môi trường `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`.

## Schema và câu hỏi tuần 1 tương ứng
| Bảng | Dùng cho |
|---|---|
| products (`stock >= 0` check, `lock_version`) | chống oversell, locking |
| orders (`idempotency_key` unique) | idempotency, `Orders::Create` |
| order_items, payments | transaction, thanh toán 3 pha |
| discount_codes (`used_count <= max_uses`) | atomic update |
| processed_events (unique) | webhook trùng, job idempotent |

Các bước 1–10 đã được cài sẵn kèm comment giải thích. Xem **ANSWERS_MAP.md** để biết file nào trả lời câu hỏi nào.

## Lưu ý test concurrency
`rails_helper` mặc định bọc mỗi test trong transaction. Với test nhiều thread/process
cùng mua món cuối, tắt `use_transactional_fixtures` cho spec đó và dọn dữ liệu thủ công,
vì mỗi thread cần connection riêng và dữ liệu phải commit thật.

## Test
`bundle exec rspec` (54 example). Test đồng thời (`create_concurrency_spec.rb`) chạy nhiều thread thật nên tắt transactional tests và tự dọn dữ liệu.

## Ghi chú MVC
- App ban đầu tạo ở API mode, sau đó chuyển sang MVC: bỏ `config.api_only`, thêm `propshaft`, `ApplicationController < ActionController::Base`.
- Gem `json` bị ghim `~> 2.15` vì `json` 3.x gây lỗi `quirks_mode` khi ActiveSupport 8.0 ghi cookie.
- Endpoint webhook (bước 5) nên tạo controller riêng kế thừa `ActionController::API`, hoặc dùng `skip_forgery_protection`, vì bên ngoài không gửi CSRF token.
