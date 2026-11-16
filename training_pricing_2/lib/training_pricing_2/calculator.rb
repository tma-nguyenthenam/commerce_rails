
require "bigdecimal"

module TrainingPricing2
  class Calculator
    def initialize(order_snapshot, config: TrainingPricing2.configuration)
      @order = order_snapshot
      @config = config
    end

    def self.call(order_snapshot, config: TrainingPricing2.configuration)
      new(order_snapshot, config: config).call
    end

    def call
      @config.validate!

      subtotal = round_amount(calculate_subtotal)

      discount_total, applied_rules = apply_discounts(subtotal)

      total = round_amount(subtotal - discount_total)

      Result.new(
        subtotal: subtotal,
        discount_total: discount_total,
        total: total,
        currency: @config.currency,
        applied_rules: applied_rules
      )
    end

    private

    def calculate_subtotal
      unless @order.is_a?(Hash)
        raise InvalidOrderError, "Order must be a Hash"
      end

      lines = @order[:lines]

      unless lines.is_a?(Array) && !lines.empty?
        raise InvalidOrderError, "Order must contain at least one line"
      end

      lines.sum(BigDecimal("0")) do |line|
        unless line.is_a?(Hash)
          raise InvalidOrderError, "Each line must be a Hash"
        end

        price = BigDecimal(line.fetch(:unit_price).to_s)
        quantity = line.fetch(:quantity)

        unless price >= 0 && quantity.is_a?(Integer) && quantity > 0
          raise InvalidOrderError, "Invalid price or quantity"
        end

        price * quantity
      rescue KeyError, ArgumentError
        raise InvalidOrderError, "Each line must have a valid unit_price and quantity"
      end
    end

    def apply_discounts(subtotal)
      discounts = @order.fetch(:discounts, [])

      unless discounts.is_a?(Array)
        raise InvalidDiscountError, "Discounts must be an array"
      end

      remaining = subtotal
      discount_total = BigDecimal("0")
      applied_rules = []

      discounts.each do |discount|
        unless discount.is_a?(Hash)
          raise InvalidDiscountError, "Discount must be a Hash"
        end

        amount = case discount[:type]
                 when :percentage
                   calculate_percentage_discount(discount, remaining)
                 when :fixed
                   calculate_fixed_discount(discount, remaining)
                 else
                   raise InvalidDiscountError, "Unsupported discount type"
                 end

        # Discount cannot exceed the remaining amount.
        amount = [amount, remaining].min

        remaining -= amount
        discount_total += amount

        applied_rules << {
          name: discount[:name],
          type: discount[:type],
          amount: amount
        }
      end

      [discount_total, discount_total.zero? ? [] : applied_rules]
    end

    def calculate_percentage_discount(discount, remaining)
      percentage = BigDecimal(discount.fetch(:value).to_s)

      unless percentage >= 0 && percentage <= 100
        raise InvalidDiscountError, "Percentage must be between 0 and 100"
      end

      round_amount(remaining * percentage / 100)
    rescue KeyError, ArgumentError
      raise InvalidDiscountError, "Invalid percentage discount"
    end

    def calculate_fixed_discount(discount, remaining)
      amount = BigDecimal(discount.fetch(:value).to_s)

      unless amount >= 0
        raise InvalidDiscountError, "Fixed discount must be non-negative"
      end

      round_amount(amount)
    rescue KeyError, ArgumentError
      raise InvalidDiscountError, "Invalid fixed discount"
    end

    def round_amount(amount)
      amount.round(@config.precision, @config.rounding_mode)
    end
  end
end
