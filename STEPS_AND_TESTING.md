# Các bước, file chính và cách test

Tài liệu tra cứu nhanh cho project Commerce API. Mỗi bước gồm: **mục tiêu**, **file chính**, **cách test tự động** và **cách thử bằng tay**.

## Chuẩn bị (làm một lần)

```bash
docker compose up -d                 # bật PostgreSQL (cổng 5433)
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server                     # http://localhost:3000
```

Chạy test: `bundle exec rspec` (cần Docker đang chạy). Một số lệnh hay dùng:

```bash
bundle exec rspec                                  # toàn bộ
bundle exec rspec spec/services                    # một thư mục
bundle exec rspec spec/services/orders/create_spec.rb:20   # một test theo số dòng
bundle exec rspec --format documentation           # in tên test dạng câu chữ
```

---

## Bước 1. Tạo đơn hàng: `Orders::Create`

**Mục tiêu:** tạo đơn và các dòng hàng nguyên tử, trả về kết quả có kiểu thay vì ném exception.

| File | Vai trò |
|---|---|
| `app/services/orders/create.rb` | Use case chính, sở hữu transaction |
| `app/services/orders/result.rb` | Kết quả có kiểu (`success?`, `error`, `replayed?`) |
| `app/controllers/orders_controller.rb` | Controller mỏng, chuyển `Result` thành redirect/render |
| `app/views/orders/new.html.erb` | Form đặt hàng |

**Test tự động:** `bundle exec rspec spec/services/orders/create_spec.rb`
Kiểm tra: đơn thành công, sản phẩm sai, thiếu hàng, idempotency key trùng, rollback, gộp dòng trùng, mã giảm giá.

**Thử bằng tay:** vào `/orders/new`, đặt hàng bình thường rồi mua quá tồn kho (sẽ báo lỗi, không bị trừ kho).

---

## Bước 2. Chống oversell khi đồng thời

**Mục tiêu:** hai request mua món cuối thì đúng một request thành công.

| File | Vai trò |
|---|---|
| `app/services/orders/create.rb` (`reserve_stock!`) | `UPDATE ... WHERE stock >= ?` nguyên tử |
| `db/migrate/*_create_products.rb` | Check constraint `stock >= 0` |

**Test tự động:** `bundle exec rspec spec/services/orders/create_concurrency_spec.rb`
Dùng nhiều thread thật, mỗi thread một connection. Kiểm tra món cuối chỉ bán một lần, cùng idempotency key đồng thời chỉ tạo một đơn, mã giảm giá `max_uses = 1` chỉ dùng một lần.

Kiểm tra có ổn định không:
```bash
for i in $(seq 1 20); do bundle exec rspec spec/services/orders/create_concurrency_spec.rb | tail -2; done
```

**Thí nghiệm nên làm:** đổi `reserve_stock!` sang kiểu "đọc rồi ghi" (`product.update!(stock: product.stock - quantity)`), tạm bỏ check constraint, rồi chạy lại spec để thấy oversell xảy ra.

---

## Bước 3. Job gửi xác nhận idempotent

**Mục tiêu:** khách chỉ nhận một email dù job chạy lại.

| File | Vai trò |
|---|---|
| `app/jobs/send_confirmation_job.rb` | "Chiếm việc" bằng `UPDATE ... WHERE confirmation_sent_at IS NULL` |
| `app/mailers/order_mailer.rb`, `app/views/order_mailer/confirmation.text.erb` | Nội dung email |

**Test tự động:** `bundle exec rspec spec/jobs/send_confirmation_job_spec.rb`
Kiểm tra: chạy hai lần chỉ gửi một email; gửi lỗi thì nhả claim và job được xếp lịch retry.

Việc "job chỉ xếp hàng sau commit" được test ở `create_spec.rb` (mục "job xác nhận").

---

## Bước 4. Thanh toán 3 pha: `Orders::Pay`

**Mục tiêu:** không giữ transaction hay lock trong lúc gọi gateway chậm.

| File | Vai trò |
|---|---|
| `app/services/orders/pay.rb` | Pha 1 (lock, `payment_pending`), pha 2 (gọi gateway), pha 3 (ghi kết quả) |
| `app/services/payments/fake_gateway.rb` | Gateway giả: chậm, lỗi ngẫu nhiên, nhớ idempotency key |

**Test tự động:** `bundle exec rspec spec/services/orders/pay_spec.rb`
Kiểm tra: thanh toán thành công, gọi lần hai trả `:already_paid` và gateway chỉ bị gọi một lần, timeout rồi thử lại, idempotency key cố định theo đơn, không giữ transaction khi gọi gateway.

**Thử bằng tay:** mở trang một đơn, bấm "Thanh toán". Gateway lỗi 20% nên có lúc báo lỗi, bấm lại là an toàn. Chỉnh bằng biến `GATEWAY_LATENCY` và `GATEWAY_FAILURE_RATE`.

---

## Bước 5. Webhook gửi trùng

**Mục tiêu:** cùng một sự kiện đến nhiều lần mà chỉ xử lý một lần.

| File | Vai trò |
|---|---|
| `app/controllers/webhooks_controller.rb` | Nhận webhook, tắt CSRF |
| `app/services/webhooks/handle_payment_event.rb` | Ghi `ProcessedEvent` và đổi trạng thái đơn trong một transaction |
| `db/migrate/*_create_processed_events.rb` | Unique index trên `external_event_id` |

**Test tự động:** `bundle exec rspec spec/requests/webhooks_spec.rb`
Kiểm tra: xử lý lần đầu, gửi trùng, đơn không tồn tại (không ghi `ProcessedEvent`), trạng thái sai.

**Thử bằng tay** (gửi hai lần, lần hai báo `duplicate:true`):
```bash
curl -X POST localhost:3000/webhooks/payments -H 'Content-Type: application/json' \
     -d '{"event_id":"e1","order_id":1,"status":"paid"}'
```
Lưu ý: lệnh này đổi trạng thái đơn trong database development.

---

## Bước 6. Giá, phí ship, mã giảm giá

**Mục tiêu:** thấy khi nào Proc là đủ và khi nào nên tách thành object.

| File | Vai trò |
|---|---|
| `app/services/pricing/calculator.rb` | Hàm thuần tính tổng, không đụng database |
| `app/services/shipping/domestic.rb`, `international.rb` | Strategy phí ship |
| `app/models/discount_code.rb` (`redeem!`) | Tăng lượt dùng nguyên tử |

**Test tự động:** `bundle exec rspec spec/services/pricing/calculator_spec.rb`
Không cần database nên chạy rất nhanh. Test mã giảm giá đồng thời nằm ở `create_concurrency_spec.rb`.

**Thử bằng tay:** ở `/orders/new`, dùng mã `SALE50` (giảm 50.000đ, tối đa 3 lần).

---

## Bước 7. Cache danh sách sản phẩm

**Mục tiêu:** cache có chủ đích, có kế hoạch khi cache hỏng.

| File | Vai trò |
|---|---|
| `app/services/catalog/products_list.rb` | Key theo version, TTL 5 phút, fallback khi cache lỗi |
| `app/controllers/products_controller.rb` | Dùng cache cho trang danh sách |

**Test tự động:** `bundle exec rspec spec/services/catalog/products_list_spec.rb`
Kiểm tra: lần hai lấy từ cache, sản phẩm đổi thì cache tự làm mới, cache hỏng vẫn trả dữ liệu từ database. Có một test ghi lại **giới hạn đã biết**: `update_all` không đổi `updated_at` nên cache bị cũ.

---

## Bước 8. Đổi tên cột `name` thành `title` (zero-downtime)

**Mục tiêu:** thực hành expand-and-contract. Project đã làm đến release 4; release cuối (xóa cột) cố ý chưa chạy.

| File | Vai trò |
|---|---|
| `db/migrate/20261106100000_add_title_to_products.rb` | Release 1: thêm cột `title` |
| `app/models/product.rb` | Ghi cả hai cột (dual-write) |
| `lib/tasks/products.rake` | Release 2: backfill theo lô, chạy lại được |
| `db/contract/*.pending` | Release 5: xóa cột `name` (chưa chạy) |

**Test tự động:** `bundle exec rspec spec/models/product_title_spec.rb`

**Thử bằng tay:** `bin/rails products:backfill_title` (đổi cỡ lô bằng `BATCH_SIZE`, thời gian nghỉ bằng `PAUSE`).

---

## Bước 9. Load test Puma

**Mục tiêu:** tự đo xem threads và workers ảnh hưởng thế nào.

| File | Vai trò |
|---|---|
| `config/puma.rb` | Cấu hình workers, threads (qua biến môi trường) |
| `app/controllers/benchmarks_controller.rb` | `/benchmark/io` (sleep 0.2s), `/benchmark/cpu` (tính toán), `/benchmark/db` (`pg_sleep`) |
| `script/load_test.rb` | Công cụ load test bằng Ruby thuần |

Bước này không có test tự động, bạn tự đo:

```bash
RAILS_MAX_THREADS=1 bin/rails server        # lần đo 1
RAILS_MAX_THREADS=5 bin/rails server        # lần đo 2 (tắt server cũ trước)
ruby script/load_test.rb http://localhost:3000/benchmark/io  10 100
ruby script/load_test.rb http://localhost:3000/benchmark/cpu 10 100
```

Ghi lại một bảng so sánh:

| Workers | Threads | Endpoint | Req/s | p95 |
|---|---|---|---|---|

Kỳ vọng: tăng threads giúp `/benchmark/io` rõ rệt, nhưng gần như không giúp `/benchmark/cpu`. Hãy kiểm chứng bằng số đo của chính bạn thay vì tin kỳ vọng này.

---

## Bước 10. `method_missing`

**Mục tiêu:** hiểu method lookup và vì sao `respond_to_missing?` đi cặp.

| File | Vai trò |
|---|---|
| `app/services/feature_flags.rb` | `Dynamic` (dùng `method_missing` trong module `Reader`) và `Defined` (method thật) |

**Test tự động:** `bundle exec rspec spec/services/feature_flags_spec.rb`

**Thử bằng tay:**
```ruby
# bin/rails console
flags = FeatureFlags::Dynamic.new(new_checkout: true, beta_ui: false)
flags.new_checkout?               # => true
flags.respond_to?(:new_checkout)  # => true
flags.new_chekout                 # NoMethodError (gõ sai tên)
FeatureFlags::Dynamic.ancestors   # có FeatureFlags::Reader
```

**Thí nghiệm:** xóa `respond_to_missing?` rồi chạy lại spec để thấy hai test fail.

---

## Chưa làm

- **Bước 11 (nâng Rails):** bước tùy chọn, cần hạ phiên bản trước rồi mới nâng.
- **Release cuối của bước 8:** file `.pending` chỉ nên chạy khi không còn code nào dùng cột `name`.

## Khi test fail

- Đọc dòng `Failure/Error`: thường nói rõ kỳ vọng và giá trị thực tế.
- Lỗi kết nối database: thường do Docker chưa chạy (`docker compose up -d`).
- Test concurrency fail ngẫu nhiên: kiểm tra số thread không vượt quá `pool` trong `database.yml` (mặc định 5).
