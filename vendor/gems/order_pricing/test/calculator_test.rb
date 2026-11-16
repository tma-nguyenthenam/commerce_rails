require_relative "test_helper"

class OrderPricingTest < Minitest::Test
  def test_fixed_discount
    snapshot = { subtotal: "100.00", fixed_discount: "15.50" }
    result = OrderPricing.calculate(snapshot)
    assert_equal BigDecimal("84.50"), result
  end

  def test_percentage_discount
    snapshot = { subtotal: "200.00", discount_type: "percentage", discount_value: "10" }
    result = OrderPricing.calculate(snapshot)
    assert_equal BigDecimal("180.00"), result
  end

  def test_percentage_discount_rounding_precision
    # BigDecimal should handle precision better than floats
    snapshot = { subtotal: "10.00", discount_type: "percentage", discount_value: "33.333" }
    result = OrderPricing.calculate(snapshot)
    # 10 - (10 * 0.33333) = 10 - 3.3333 = 6.6667
    assert_equal BigDecimal("6.6667"), result.round(4)
  end

  def test_negative_total_capped_at_zero
    snapshot = { subtotal: "10.00", fixed_discount: "50.00" }
    result = OrderPricing.calculate(snapshot)
    assert_equal BigDecimal("0"), result
  end

  def test_raises_error_on_missing_subtotal
    error = assert_raises(OrderPricing::Error) do
      OrderPricing.calculate({})
    end
    assert_match(/Subtotal is required/, error.message)
  end

  def test_raises_error_on_invalid_number
    error = assert_raises(OrderPricing::Error) do
      OrderPricing.calculate({ subtotal: "abc" })
    end
    assert_match(/Invalid numeric format/, error.message)
  end
end
