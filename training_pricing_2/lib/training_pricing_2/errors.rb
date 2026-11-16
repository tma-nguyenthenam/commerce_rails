
module TrainingPricing2
  class Error < StandardError; end

  class InvalidOrderError < Error; end

  class InvalidDiscountError < Error; end

  class InvalidConfigurationError < Error; end
end
