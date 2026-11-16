
module TrainingPricing2
  class Result
    attr_reader :subtotal, :discount_total, :total, :currency, :applied_rules

    def initialize(subtotal:, discount_total:, total:, currency:, applied_rules:)
      @subtotal = subtotal
      @discount_total = discount_total
      @total = total
      @currency = currency
      @applied_rules = applied_rules.freeze
    end
  end
end
