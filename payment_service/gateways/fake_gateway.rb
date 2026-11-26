
require "securerandom"

class FakeGateway
  def initialize(latency: 1)
    @latency = latency
  end

  def charge(amount:)
    puts ">>> FakeGateway is called!"
    sleep @latency

    {
      success: true,
      external_id: "pay_#{SecureRandom.hex(8)}",
      amount: amount
    }
  end
end
