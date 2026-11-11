# Thứ tự làm gợi ý — Commerce API

Mỗi bước chỉ cần đủ để trả lời được **một câu hỏi phỏng vấn** bằng ví dụ thật từ code của bạn. Làm tuần tự, vì bước sau dùng lại bước trước.

Câu hỏi được đánh số theo `Week_01_Interview_Questions_Explained.md` (Q1–Q12).

| Bước | Nội dung | Câu hỏi | Ước lượng |
|---|---|---|---|
| 0 | Kiểm tra môi trường | — | 10 phút |
| 1 | `Orders::Create` | Q4, Q6 | 1.5–2 giờ |
| 2 | Chống oversell khi đồng thời | Q4 | 1 giờ |
| 3 | `SendConfirmationJob` | Q5, Q6 | 1 giờ |
| 4 | Thanh toán 3 pha | Q4, Q10 | 1.5 giờ |
| 5 | Webhook trùng | Q5 | 45 phút |
| 6 | Giảm giá và phí ship | Q2, Q8 | 1 giờ |
| 7 | Cache danh sách sản phẩm | Q9 | 45 phút |
| 8 | Đổi tên cột zero-downtime | Q7 | 1 giờ |
| 9 | Load test Puma | Q3 | 45 phút |
| 10 | Config động | Q1 | 30 phút |
| 11 | Nâng Rails | Q11 | tùy chọn |
| 12 | Tổng kết | Q12 | 30 phút |

---

## Bước 0 — Kiểm tra môi trường

```bash
docker compose up -d
bin/rails db:migrate
bundle exec rspec          # phải xanh (2 example)
```

**Xong khi:** `rspec` pass, `bin/rails db:seed` chạy được và `bin/rails server` hiện dữ liệu ở http://localhost:3000.

---

## Bước 1 — `Orders::Create` (lab chính)

**Mục tiêu:** tạo đơn hàng nguyên tử, trả về kết quả có kiểu, không để exception của database lọt ra ngoài.

**File:** `app/services/orders/create.rb`, `spec/services/orders/create_spec.rb`

**Làm:**
1. Định nghĩa `Result` (success/failure kèm `order` hoặc `error`).
2. Kiểm tra sản phẩm tồn tại và số lượng hợp lệ.
3. Tính tiền bằng `BigDecimal`, không dùng `Float`.
4. Bọc việc tạo `Order` và `OrderItem` trong **một** transaction.
5. Nhận `idempotency_key`. Nếu key đã có thì trả lại đơn cũ.
6. Ghi structured log kèm `request_id` và `order_id`.

**Test:**
- Đơn thành công.
- Sản phẩm không tồn tại trả `:invalid_product`.
- Rollback: tạo item thứ hai thất bại thì không còn order nào trong database.

**Xong khi:** các test trên pass và không có `ActiveRecord::*` nào bị raise ra khỏi `call`.

**Hỏi bản thân (Q4):** transaction nằm ở đâu và vì sao ở đó?

---

## Bước 2 — Chống oversell khi đồng thời

**Mục tiêu:** hai request mua món cuối cùng thì đúng một request thành công.

**Làm:**
1. Trừ kho bằng một câu `UPDATE ... WHERE stock >= ?` (`update_all`), kiểm tra số dòng bị ảnh hưởng.
2. Raise lỗi nội bộ khi số dòng bằng 0 để transaction rollback, sau đó chuyển thành `:insufficient_stock`.
3. Khi đơn có nhiều sản phẩm, xử lý theo thứ tự `product_id` tăng dần để tránh deadlock.

**Test concurrency:** chạy nhiều thread thật, mỗi thread dùng connection riêng.
- Tắt `use_transactional_fixtures` cho spec này (xem README).
- Tạo sản phẩm `stock: 1`, chạy 5 thread cùng tạo đơn với `idempotency_key` khác nhau.
- Kỳ vọng: đúng 1 thành công, 4 `:insufficient_stock`, `stock` cuối bằng 0.
- Thêm test: key trùng gửi đồng thời chỉ tạo 1 đơn (unique index chặn, bạn bắt `RecordNotUnique`).

**Xong khi:** chạy test concurrency 20 lần liên tiếp không lần nào flaky.

**Thử nghiệm đáng làm:** tạm bỏ check constraint `stock >= 0` và đổi sang cách "đọc rồi ghi" (`product.stock -= qty; product.save`). Chạy lại test, xem oversell xảy ra thế nào. Đây là ví dụ thật cho "database là authority".

---

## Bước 3 — `SendConfirmationJob`

**Mục tiêu:** gửi xác nhận đúng một lần dù job chạy lại.

**Làm:**
1. Thêm backend job (gợi ý: Sidekiq + Redis, hoặc tạm dùng adapter `:async`/`:test` khi chỉ học).
2. Job nhận `order_id`, không nhận object.
3. Dùng cột `confirmation_sent_at` để "chiếm việc" bằng `UPDATE ... WHERE confirmation_sent_at IS NULL`.
4. Trong `Orders::Create`, đưa job vào hàng đợi **sau khi** transaction commit (hoặc dùng `after_commit`).

**Test:**
- Job chạy hai lần chỉ gửi một mail.
- Retry: lần 1 lỗi mạng, lần 2 thành công.
- Transaction rollback thì không có job nào được enqueue.

**Xong khi:** bạn giải thích được vì sao `after_save` sẽ làm test thứ ba fail.

**Câu hỏi mở:** nếu mail lỗi sau khi đã đánh dấu `confirmation_sent_at` thì sao? Cân nhắc thêm trạng thái `sending` rồi `sent`.

---

## Bước 4 — Thanh toán 3 pha

**Mục tiêu:** không giữ transaction hay lock trong lúc gọi gateway chậm.

**File:** `app/services/payments/fake_gateway.rb`, `app/services/orders/pay.rb`

**Làm:**
1. `FakeGateway#charge` có độ trễ (`sleep`) và lỗi ngẫu nhiên, nhận `idempotency_key`.
2. `Orders::Pay` chia ba pha:
   - Pha 1 (transaction ngắn, `lock`): kiểm tra chưa trả tiền, chuyển `payment_pending`.
   - Pha 2 (ngoài transaction): gọi gateway.
   - Pha 3: ghi `Payment` và chuyển `paid` hoặc `payment_failed`.

**Test:**
- Mock gateway (nó là ranh giới bạn không sở hữu), nhưng dùng database thật.
- Gọi `Orders::Pay` hai lần liên tiếp: lần hai trả `:already_paid`, gateway chỉ bị gọi một lần.
- Gateway timeout: đơn ở trạng thái xử lý được tiếp, không kẹt vĩnh viễn.

**Xong khi:** bạn chỉ ra được đoạn nào của code sẽ giữ connection 3 giây nếu gộp cả ba pha vào một transaction.

---

## Bước 5 — Webhook trùng

**Mục tiêu:** gateway gửi cùng một sự kiện hai lần mà chỉ xử lý một lần.

**File:** `app/controllers/webhooks_controller.rb`, `app/services/webhooks/handle_payment_event.rb`

**Làm:**
1. Endpoint `POST /webhooks/payments` nhận `event_id`. Project đã là MVC nên controller này cần `skip_forgery_protection` (hoặc kế thừa `ActionController::API`), vì bên ngoài không gửi CSRF token.
2. `ProcessedEvent.create!(external_event_id: ...)` rồi mới áp dụng thay đổi, bắt `RecordNotUnique` để bỏ qua.
3. Đặt việc ghi `ProcessedEvent` và việc áp dụng thay đổi **trong cùng transaction**, để lỗi giữa chừng thì cả hai cùng rollback.

**Test (request spec):** gửi cùng payload 2 lần, cả hai trả 200, đơn chỉ đổi trạng thái một lần.

**Xong khi:** bạn giải thích được vì sao ghi `ProcessedEvent` sau khi áp dụng thay đổi là sai.

---

## Bước 6 — Giảm giá và phí ship

**Mục tiêu:** thấy khi nào Proc là đủ và khi nào cần tách thành object.

**Làm:**
1. Bắt đầu bằng một lambda tính phí ship, viết thẳng trong `Orders::Create`.
2. Thêm luật mới (miễn phí ship trên 500.000, phí quốc tế, hạng thành viên). Khi lambda khó đọc thì tách thành `Shipping::Domestic` và `Shipping::International` cùng interface `call(order)`.
3. `Pricing::Calculator` là hàm thuần (không đụng database) để test nhanh.
4. Mã giảm giá: tăng `used_count` bằng `UPDATE ... WHERE used_count < max_uses`.

**Test:** `Pricing::Calculator` không cần database. Mã giảm giá `max_uses: 1` dùng đồng thời chỉ nhận được một lần.

**Xong khi:** bạn nói được thời điểm cụ thể bạn chuyển từ lambda sang object và lý do.

**Với Q8:** nhìn lại `Orders::Create`. Có đoạn nào có lý do thay đổi khác với phần còn lại không? Chỉ tách những đoạn đó.

---

## Bước 7 — Cache danh sách sản phẩm

**Mục tiêu:** cache có chủ đích, có kế hoạch khi cache hỏng.

**Làm:**
1. `GET /products` dùng `Rails.cache.fetch` với key theo version (`cache_key_with_version` hoặc kết hợp `maximum(:updated_at)` và `count`).
2. Đặt TTL ngắn làm lưới an toàn.
3. Quyết định hành vi khi cache lỗi (fallback về database, ghi log).
4. Thử `update_all` trên sản phẩm và quan sát cache có tươi không (`updated_at` không đổi, nên key không đổi).

**Xong khi:** bạn nêu được một trường hợp cache sẽ cũ và vì sao bạn chấp nhận hoặc xử lý nó.

---

## Bước 8 — Đổi tên cột zero-downtime

**Mục tiêu:** thực hành expand-and-contract với đúng dữ liệu thật.

**Làm:** đổi `products.name` thành `products.title` qua các release riêng, mỗi release là một commit riêng.

1. Thêm cột `title`, ghi cả hai cột.
2. Backfill theo lô (`in_batches`), có thể chạy lại, có nghỉ giữa các lô.
3. Chuyển đọc sang `title`.
4. Ngừng ghi `name`, thêm `ignored_columns`.
5. Xóa cột `name`.

**Mẹo kiểm chứng:** tạo 100.000 sản phẩm bằng seed trước khi backfill. Trong lúc backfill chạy, mở `psql` xem `pg_stat_activity` để thấy tác động lên database.

**Xong khi:** mỗi commit khi deploy riêng lẻ đều chạy được với code của commit trước đó.

---

## Bước 9 — Load test Puma

**Mục tiêu:** tự đo, không đoán.

**Làm:**
1. Chạy production-like: `RAILS_ENV=production`, thử `WEB_CONCURRENCY=1` rồi `2`, và `RAILS_MAX_THREADS=1` rồi `5`.
2. Công cụ: `wrk` hoặc `ab`.
3. Với hai loại endpoint:
   - I/O-bound: `GET /products` kèm `sleep 0.2` giả lập API ngoài.
   - CPU-bound: một endpoint tính toán Ruby thuần.
4. Hạ `pool` xuống nhỏ hơn số thread để tận mắt thấy `ConnectionTimeoutError`.

**Ghi lại một bảng:**

| Workers | Threads | Endpoint | Req/s | p95 |
|---|---|---|---|---|

**Xong khi:** bảng cho thấy threads giúp ích cho I/O-bound nhưng không giúp CPU-bound.

---

## Bước 10 — Config động

**Mục tiêu:** hiểu `method_missing` bằng một ví dụ nhỏ.

**Làm:** viết `FeatureFlags` đọc từ hash, truy cập kiểu `flags.new_checkout?`, cài bằng `method_missing` và `respond_to_missing?` đặt trong một module. Sau đó viết lại bằng `define_singleton_method` và so sánh.

**Test:** `respond_to?` đúng, `method(:x)` hoạt động, tên sai ném `NoMethodError` (không trả `nil`).

---

## Bước 11 — Nâng Rails (tùy chọn)

Chỉ làm nếu còn thời gian. Hạ project xuống một phiên bản Rails cũ hơn rồi tự nâng lên, theo quy trình trong Q11: baseline xanh, từng bước, dọn deprecation, bật defaults dần.

---

## Bước 12 — Tổng kết

Với mỗi câu Q1–Q12, ghi ra **một dòng** trỏ tới code cụ thể trong project:

```
Q4: app/services/orders/pay.rb, 3 pha, transaction chỉ ở pha 1
Q5: app/jobs/send_confirmation_job.rb, UPDATE có điều kiện trên confirmation_sent_at
```

Sau đó tự trả lời thành tiếng mỗi câu trong dưới 2 phút theo công thức **Kết luận, Lý do, Ví dụ, Trade-off**, và đối chiếu với checklist cuối file tuần 1.

---

## Nguyên tắc khi làm

- **Test trước hoặc cùng lúc**, đặc biệt các test concurrency. Chúng là bằng chứng bạn hiểu bài.
- **Mỗi bước một commit** (hoặc nhiều), để dễ quay lại và dễ kể lại.
- **Đừng làm cho đẹp sớm.** Bước 6 và 8 trong danh sách này cố ý để bạn viết bản đơn giản trước rồi mới cải tiến.
- Khi mắc kẹt, ghi lại lỗi gặp phải. Câu chuyện "tôi gặp lỗi X vì Y" thường là ví dụ phỏng vấn tốt nhất.
