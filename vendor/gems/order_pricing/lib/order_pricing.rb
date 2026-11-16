# frozen_string_literal: true

require_relative "order_pricing/version"
require_relative "order_pricing/error"
require_relative "order_pricing/calculator"

module OrderPricing
  class << self
    # Public entry point
    def calculate(snapshot)
      Calculator.new(snapshot).total
    end
  end
end