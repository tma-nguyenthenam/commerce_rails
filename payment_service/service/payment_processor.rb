
require "thread"

class PaymentProcessor
  def initialize(gateway:)
    @gateway = gateway
    @payments = {}
    @mutex = Mutex.new
  end

  def charge(amount:, idempotency_key:)
    validate!(amount, idempotency_key)

    @mutex.synchronize do
      # Return existing payment if already processed
      if @payments.key?(idempotency_key)
        puts "Returning existing payment: #{idempotency_key}"
        return @payments[idempotency_key]
      end

      # Process new payment
      payment = @gateway.charge(amount: amount)

      # Store result for future duplicate requests
      @payments[idempotency_key] = payment

      puts "Payment created: #{idempotency_key}"

      payment
    end
  end

  private

  def validate!(amount, idempotency_key)
    unless valid_amount?(amount)
      raise ArgumentError, "invalid_amount"
    end

    if idempotency_key.nil? || idempotency_key.empty?
      raise ArgumentError, "missing_idempotency_key"
    end
  end

  def valid_amount?(amount)
    Float(amount).positive?
  rescue ArgumentError, TypeError
    false
  end
end
