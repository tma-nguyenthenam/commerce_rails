# Bản đồ: câu hỏi phỏng vấn → code trong project

Mỗi file đều có comment tiếng Việt giải thích *vì sao*. Đọc theo thứ tự bảng dưới.

| Q | Chủ đề | Đọc file nào | Test chứng minh |
|---|---|---|---|
| Q1 | `method_missing` / `respond_to_missing?` | `app/services/feature_flags.rb` | `spec/services/feature_flags_spec.rb` |
| Q2 | Proc vs strategy object | `app/services/shipping/*.rb`, `pricing/calculator.rb` | `spec/services/pricing/calculator_spec.rb` |
| Q3 | GVL và Puma | `config/puma.rb`, `app/controllers/benchmarks_controller.rb`, `script/load_test.rb` | tự chạy load test (bên dưới) |
| Q4 | Ranh giới transaction | `app/services/orders/create.rb`, `orders/pay.rb` | `create_spec.rb` (rollback), `pay_spec.rb` (không giữ transaction khi gọi gateway) |
| Q5 | Job / webhook idempotent | `app/jobs/send_confirmation_job.rb`, `webhooks/handle_payment_event.rb` | `send_confirmation_job_spec.rb`, `webhooks_spec.rb` |
| Q6 | `after_save` vs sau commit | `Orders::Create` (bước 4 trong `call`) | `create_spec.rb` ("KHÔNG xếp hàng job khi rollback") |
| Q7 | Đổi tên cột zero-downtime | `db/migrate/*add_title*`, `lib/tasks/products.rake`, `app/models/product.rb`, `db/contract/*.pending` | `spec/models/product_title_spec.rb` |
| Q8 | Tách service lớn | `Orders::Create` (lõi) + `Pricing::Calculator` (luật giá) + `Shipping::*` (strategy) | `calculator_spec.rb` không cần DB |
| Q9 | Cache invalidation | `app/services/catalog/products_list.rb` | `products_list_spec.rb` (gồm giới hạn đã biết) |
| Q10 | Mock gì | `spec/services/orders/pay_spec.rb` (mock gateway, DB thật) | chính file đó |
| Q11 | Nâng Rails | *Chưa làm* (bước tùy chọn) | — |
| Q12 | Senior là gì | Xem các comment "GIỚI HẠN ĐÃ BIẾT" và "Vì sao" xuyên suốt code | — |

## Chạy thử bằng tay

```bash
docker compose up -d && bin/rails db:migrate db:seed
bin/rails server                       # http://localhost:3000
```

* **/orders/new**: đặt hàng. Thử mua quá tồn kho; bấm đúp nút; dùng mã `SALE50` (tối đa 3 lần).
* **Trang đơn → "Thanh toán"**: gateway giả chậm 1s, lỗi 20%. Bấm lại sau khi lỗi là an toàn.
* **Webhook trùng**:
  ```bash
  curl -X POST localhost:3000/webhooks/payments -H 'Content-Type: application/json' \
       -d '{"event_id":"e1","order_id":1,"status":"paid"}'   # gửi 2 lần, lần 2 báo duplicate:true
  ```
* **Backfill bước 8**: `bin/rails products:backfill_title`
* **Load test bước 9** (nên chạy `RAILS_ENV=production`, cần `SECRET_KEY_BASE` và DB production, hoặc tạm dùng development để làm quen):
  ```bash
  WEB_CONCURRENCY=0 RAILS_MAX_THREADS=1 bin/rails s      # so sánh với RAILS_MAX_THREADS=5
  ruby script/load_test.rb http://localhost:3000/benchmark/io  10 100
  ruby script/load_test.rb http://localhost:3000/benchmark/cpu 10 100
  ```
  Kỳ vọng: threads tăng thì `/benchmark/io` nhanh hơn rõ rệt, còn `/benchmark/cpu` gần như không đổi.

## Thử nghiệm nên tự làm để hiểu sâu

1. **Oversell:** trong `Orders::Create#reserve_stock!`, tạm đổi thành `product.update!(stock: product.stock - quantity)` (và bỏ check constraint `products_stock_non_negative` trong DB test). Chạy `create_concurrency_spec.rb` và xem test fail ra sao.
2. **`after_save`:** thử thay `perform_later` bằng callback `after_save` trong `Order`, chạy test "KHÔNG xếp hàng job khi rollback".
3. **Connection pool:** đặt `pool: 1` trong `database.yml`, chạy `RAILS_MAX_THREADS=3` rồi gọi `/benchmark/db` đồng thời để thấy `ConnectionTimeoutError`.
