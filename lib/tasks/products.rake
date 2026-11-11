namespace :products do
  desc "Bước 8 (RELEASE 2): điền products.title từ products.name theo từng lô"
  task backfill_title: :environment do
    batch_size = ENV.fetch("BATCH_SIZE", 1_000).to_i
    pause = ENV.fetch("PAUSE", 0.1).to_f
    total = 0

    # Chỉ xử lý dòng CHƯA có title -> chạy lại bao nhiêu lần cũng được (resumable),
    # bị ngắt giữa chừng thì chạy lại sẽ tiếp tục từ chỗ dở.
    # in_batches: mỗi lần lấy một lô theo khóa chính, không nạp cả bảng vào RAM.
    Product.where(title: nil).in_batches(of: batch_size) do |batch|
      total += batch.update_all("title = name") # SQL thuần: không tạo object Ruby, không chạy callback
      sleep(pause) # nhường DB cho request thật (rate limit)
    end

    puts "Backfill xong: #{total} dòng. Còn thiếu title: #{Product.where(title: nil).count}"
  end
end
