
require "sinatra"
require "json"
require "securerandom"

class PaymentService < Sinatra::Base
  set :host_authorization, {
    permitted_hosts: [
      "payment_service",
      "localhost",
      "127.0.0.1"
    ]
  }
  # Lưu kết quả thanh toán theo idempotency key
  GATEWAY_LATENCY = ENV.fetch("GATEWAY_LATENCY", "1").to_f
  PAYMENTS = {}

  before do
    content_type :json
  end

  get "/health" do
    {
      service: "payment_service",
      status: "ok"
    }.to_json
  end

  
  post "/payments/charge" do
    data = JSON.parse(request.body.read)

    amount = data["amount"]
    idempotency_key = data["idempotency_key"]

    if amount.nil? || amount.to_f <= 0
        status 422
        return { error: "invalid_amount" }.to_json
    end

    if idempotency_key.nil? || idempotency_key.empty?
        status 422
        return { error: "missing_idempotency_key" }.to_json
    end

    # 1. Kiểm tra giao dịch đã tồn tại
    if PAYMENTS.key?(idempotency_key)
        puts "Returning existing payment: #{idempotency_key}"

        return PAYMENTS[idempotency_key].to_json
    end

    # 2. Tạo giao dịch
    payment = {
        success: true,
        external_id: "pay_#{SecureRandom.hex(8)}",
        amount: amount
    }

    # 3. Lưu kết quả trước khi trả response
    PAYMENTS[idempotency_key] = payment

    puts "Payment created: #{payment[:external_id]}"

    # 4. Mô phỏng xử lý chậm
    sleep GATEWAY_LATENCY

    # 5. Trả kết quả
    payment.to_json
  end

end
