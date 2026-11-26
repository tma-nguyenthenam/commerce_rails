
class PaymentProcessor
  def initialize(gateway:, provider:)
    @gateway = gateway
    @provider = provider
  end

  def charge(order_id:, amount:, idempotency_key:)
    validate!(order_id, amount, idempotency_key)

    existing_payment = Payment.find_by(
      idempotency_key: idempotency_key
    )

    return payment_response(existing_payment) if existing_payment

    payment = Payment.create!(
      order_id: order_id,
      amount: amount,
      idempotency_key: idempotency_key,
      status: "pending"
    )

    result = @gateway.charge(amount: amount)

    unless result[:success]
      payment.update!(status: "failed")
      return payment_response(payment)
    end

    payment.update!(
      external_id: result[:external_id]
    )

    @provider.charge(
      external_id: payment.external_id,
      order_id: payment.order_id,
      amount: payment.amount
    )

    payment_response(payment)

  rescue ActiveRecord::RecordNotUnique
    payment = Payment.find_by!(
      idempotency_key: idempotency_key
    )

    payment_response(payment)
  end

  private

  def validate!(order_id, amount, idempotency_key)
    raise ArgumentError, "missing_order_id" if order_id.nil?

    if idempotency_key.nil? || idempotency_key.empty?
      raise ArgumentError, "missing_idempotency_key"
    end

    valid_amount = begin
      Float(amount).positive?
    rescue ArgumentError, TypeError
      false
    end

    raise ArgumentError, "invalid_amount" unless valid_amount
  end

  def payment_response(payment)
    {
      success: payment.status == "paid",
      external_id: payment.external_id,
      amount: payment.amount,
      status: payment.status
    }
  end
end
