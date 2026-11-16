
require_relative "test_helper"

class CalculatorTest < Minitest::Test
  def setup
    @order = {
      lines: [
        { unit_price: "100000", quantity: 2 },
        { unit_price: "150000", quantity: 1 }
      ]
    }
  end

  # Test 1: Calculate subtotal without discounts
  def test_calculates_subtotal
    result = TrainingPricing2::Calculator.call(@order)

    assert_equal BigDecimal("350000"), result.subtotal
    assert_equal BigDecimal("0"), result.discount_total
    assert_equal BigDecimal("350000"), result.total
  end

  # Test 2: Apply percentage discount
  def test_applies_percentage_discount
    @order[:discounts] = [
      { name: "Summer Sale", type: :percentage, value: "10" }
    ]

    result = TrainingPricing2::Calculator.call(@order)

    assert_equal BigDecimal("35000"), result.discount_total
    assert_equal BigDecimal("315000"), result.total
  end

  # Test 3: Apply fixed discount
  def test_applies_fixed_discount
    @order[:discounts] = [
      { name: "Coupon", type: :fixed, value: "20000" }
    ]

    result = TrainingPricing2::Calculator.call(@order)

    assert_equal BigDecimal("20000"), result.discount_total
    assert_equal BigDecimal("330000"), result.total
  end

  # Test 4: Apply multiple discounts
  def test_applies_multiple_discounts
    @order[:discounts] = [
      { name: "Summer Sale", type: :percentage, value: "10" },
      { name: "Coupon", type: :fixed, value: "20000" }
    ]

    result = TrainingPricing2::Calculator.call(@order)

    assert_equal BigDecimal("55000"), result.discount_total
    assert_equal BigDecimal("295000"), result.total
    assert_equal 2, result.applied_rules.size
  end

  # Test 5: Discount cannot exceed subtotal
  def test_discount_cannot_exceed_subtotal
    @order[:discounts] = [
      { name: "Big Coupon", type: :fixed, value: "500000" }
    ]

    result = TrainingPricing2::Calculator.call(@order)

    assert_equal BigDecimal("350000"), result.discount_total
    assert_equal BigDecimal("0"), result.total
  end

  # Test 6: Reject invalid order
  def test_rejects_empty_order
    invalid_order = { lines: [] }

    assert_raises(TrainingPricing2::InvalidOrderError) do
      TrainingPricing2::Calculator.call(invalid_order)
    end
  end

  # Test 7: Reject invalid percentage
  def test_rejects_invalid_percentage
    @order[:discounts] = [
      { name: "Invalid Sale", type: :percentage, value: "150" }
    ]

    assert_raises(TrainingPricing2::InvalidDiscountError) do
      TrainingPricing2::Calculator.call(@order)
    end
  end

  # Test 8: Reject unsupported discount type
  def test_rejects_unsupported_discount_type
    @order[:discounts] = [
      { name: "Unknown", type: :unknown, value: "10000" }
    ]

    assert_raises(TrainingPricing2::InvalidDiscountError) do
      TrainingPricing2::Calculator.call(@order)
    end
  end

    # Test 9: Reject invalid unit price
  def test_rejects_invalid_unit_price
    @order[:lines] = [
      { unit_price: "abc", quantity: 2 }
    ]

    assert_raises(TrainingPricing2::InvalidOrderError) do
      TrainingPricing2::Calculator.call(@order)
    end
  end

  # Test 10: Reject invalid quantity
  def test_rejects_invalid_quantity
    @order[:lines] = [
      { unit_price: "100000", quantity: 0 }
    ]

    assert_raises(TrainingPricing2::InvalidOrderError) do
      TrainingPricing2::Calculator.call(@order)
    end
  end

  # Test 11: Reject negative fixed discount
  def test_rejects_negative_fixed_discount
    @order[:discounts] = [
      { name: "Invalid Coupon", type: :fixed, value: "-10000" }
    ]

    assert_raises(TrainingPricing2::InvalidDiscountError) do
      TrainingPricing2::Calculator.call(@order)
    end
  end

  # Test 12: Apply percentage discounts sequentially
  def test_applies_percentage_discounts_sequentially
    @order[:discounts] = [
      { name: "Sale 1", type: :percentage, value: "10" },
      { name: "Sale 2", type: :percentage, value: "10" }
    ]

    result = TrainingPricing2::Calculator.call(@order)

    assert_equal BigDecimal("66500"), result.discount_total
    assert_equal BigDecimal("283500"), result.total
  end

  # Test 13: Round amount based on configuration
  def test_rounds_amount_using_configuration
    @order[:lines] = [
      { unit_price: "100.6", quantity: 1 }
    ]

    config = TrainingPricing2::Configuration.new
    config.precision = 0
    config.rounding_mode = BigDecimal::ROUND_HALF_UP

    result = TrainingPricing2::Calculator.call(@order, config: config)

    assert_equal BigDecimal("101"), result.subtotal
    assert_equal BigDecimal("101"), result.total
  end
end
