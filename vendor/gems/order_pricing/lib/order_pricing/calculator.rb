require "bigdecimal"
require_relative "error"

module OrderPricing
  class Calculator
    # Receives a snapshot hash. Example:
    # { subtotal: "100.00", discount_type: "percentage", discount_value: "10" }
    # Or { subtotal: "100.00", fixed_discount: "15.00" }

    def initialize(snapshot)
      @snapshot = snapshot
      validate_snapshot!
    end

    def total
      calculate_total
    rescue ArgumentError => e
      raise OrderPricing::Error, "Invalid numeric format: #{e.message}"
    end

    private

    def calculate_total
      subtotal = to_big_decimal(@snapshot[:subtotal])
      
      discount = if @snapshot[:discount_type] == "percentage"
                   calculate_percentage_discount(subtotal)
                 elsif @snapshot[:fixed_discount]
                   to_big_decimal(@snapshot[:fixed_discount])
                 else
                   BigDecimal("0")
                 end

      final_total = subtotal - discount
      # Ensure we don't return a negative total due to excessive discounts
      final_total.negative? ? BigDecimal("0") : final_total
    end

    def calculate_percentage_discount(subtotal)
      rate = to_big_decimal(@snapshot[:discount_value]) / BigDecimal("100")
      (subtotal * rate)
    end

    def to_big_decimal(value)
      raise OrderPricing::Error, "Missing numeric value" if value.nil?
      BigDecimal(value.to_s)
    end

    def validate_snapshot!
      raise OrderPricing::Error, "Snapshot must be a Hash" unless @snapshot.is_a?(Hash)
      raise OrderPricing::Error, "Subtotal is required" if @snapshot[:subtotal].nil?
      
      if @snapshot[:discount_type] == "percentage" && @snapshot[:discount_value].nil?
        raise OrderPricing::Error, "Percentage discount requires a discount_value"
      end
    end
  end
end