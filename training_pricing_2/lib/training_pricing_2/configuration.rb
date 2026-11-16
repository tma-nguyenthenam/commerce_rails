
require "bigdecimal"

module TrainingPricing2
  class Configuration
    ROUNDING_MODES = [
      BigDecimal::ROUND_UP,
      BigDecimal::ROUND_DOWN,
      BigDecimal::ROUND_HALF_UP,
      BigDecimal::ROUND_HALF_DOWN,
      BigDecimal::ROUND_HALF_EVEN,
      BigDecimal::ROUND_CEILING,
      BigDecimal::ROUND_FLOOR
    ].freeze

    attr_accessor :currency, :precision, :rounding_mode

    def initialize
      @currency = "VND"
      @precision = 2
      @rounding_mode = BigDecimal::ROUND_HALF_UP
    end

    def validate!
      unless currency.is_a?(String) && currency.match?(/\A[A-Z]{3}\z/)
        raise InvalidConfigurationError, "Currency must be a 3-letter uppercase code"
      end

      unless precision.is_a?(Integer) && precision >= 0
        raise InvalidConfigurationError, "Precision must be a non-negative integer"
      end

      unless ROUNDING_MODES.include?(rounding_mode)
        raise InvalidConfigurationError, "Invalid rounding mode"
      end
    end
  end
end
