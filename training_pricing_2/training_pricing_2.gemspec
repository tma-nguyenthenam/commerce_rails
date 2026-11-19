# frozen_string_literal: true

require_relative "lib/training_pricing_2/version"

Gem::Specification.new do |spec|
  spec.name = "training_pricing_2"
  spec.version = TrainingPricing2::VERSION
  
  spec.authors = ["Nam Nguyen"]
  spec.email = ["nthenam@tma.com.vn"]

  spec.summary = "A Ruby gem for calculating order pricing and discounts"
  spec.description = "Calculate order subtotals, percentage discounts and fixed discounts."
  spec.homepage = "https://github.com/tma-nguyenthenam/commerce_rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"
  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tma-nguyenthenam/commerce_rails"
  spec.metadata["changelog_uri"] = "https://github.com/tma-nguyenthenam/commerce_rails/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = Dir.chdir(__dir__) do
    files = Dir.glob("{lib,exe}/**/*")
    files.select! { |file| File.file?(file) }

    files + %w[README.md LICENSE.txt CHANGELOG.md]
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 6.1"  
  spec.add_dependency "bigdecimal"

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
