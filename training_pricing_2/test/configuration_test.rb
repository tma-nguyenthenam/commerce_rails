
require_relative "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @config = TrainingPricing2::Configuration.new
  end

  # Test 1: Default configuration
  def test_default_configuration
    assert_equal "VND", @config.currency
    assert_equal 2, @config.precision
    assert_equal BigDecimal::ROUND_HALF_UP, @config.rounding_mode
  end

  # Test 2: Accept valid configuration
  def test_accepts_valid_configuration
    @config.currency = "USD"
    @config.precision = 2
    @config.rounding_mode = BigDecimal::ROUND_HALF_UP

    assert_nil @config.validate!
  end

  # Test 3: Reject invalid currency
  def test_rejects_invalid_currency
    @config.currency = "usd"

    assert_raises(TrainingPricing2::InvalidConfigurationError) do
      @config.validate!
    end
  end

  # Test 4: Reject invalid precision
  def test_rejects_negative_precision
    @config.precision = -1

    assert_raises(TrainingPricing2::InvalidConfigurationError) do
      @config.validate!
    end
  end

  # Test 5: Reject non-integer precision
  def test_rejects_non_integer_precision
    @config.precision = 2.5

    assert_raises(TrainingPricing2::InvalidConfigurationError) do
      @config.validate!
    end
  end

  # Test 6: Reject invalid rounding mode
  def test_rejects_invalid_rounding_mode
    @config.rounding_mode = :invalid

    assert_raises(TrainingPricing2::InvalidConfigurationError) do
      @config.validate!
    end
  end
end
