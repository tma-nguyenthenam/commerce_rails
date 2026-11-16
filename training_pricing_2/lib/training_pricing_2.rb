require_relative "training_pricing_2/version"
require_relative "training_pricing_2/errors"
require_relative "training_pricing_2/configuration"
require_relative "training_pricing_2/result"
require_relative "training_pricing_2/calculator"

module TrainingPricing2
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
      configuration.validate!
    end

    def reset_config!
      @configuration = Configuration.new
    end
  end
end
