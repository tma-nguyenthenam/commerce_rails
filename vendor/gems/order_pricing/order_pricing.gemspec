# frozen_string_literal: true

require_relative "lib/order_pricing/version"

Gem::Specification.new do |spec|
  spec.name = "order_pricing"
  spec.version = OrderPricing::VERSION
  spec.authors = ["Order_pricing"]
  spec.email = ["order_pricing@commerce_rails.github.io"]

  spec.summary = "Calculates fixed and percentage discounts for order snapshots."
  spec.description = "A Rails 8 compatible gem that uses BigDecimal for precise financial calculations."
  spec.homepage = "https://github.com/tma-nguyenthenam/commerce_rails"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://github.com"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tma-nguyenthenam/commerce_rails"
  spec.metadata["changelog_uri"] = "https://github.com/tma-nguyenthenam/commerce_rails"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
