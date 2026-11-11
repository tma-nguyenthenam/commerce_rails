# frozen_string_literal: true

# ════════════════════════════════════════════════════════════════════════════
# Bước 10 — method_missing (Q1). Hai cách cài đặt cùng một giao diện:
#
#   flags = FeatureFlags::Dynamic.new(new_checkout: true, beta_ui: false)
#   flags.new_checkout?   # => true
#   flags.beta_ui         # => false
#   flags.typo?           # => NoMethodError (đúng! không bị nuốt)
# ════════════════════════════════════════════════════════════════════════════
module FeatureFlags
  # Cách 1: method_missing. Method KHÔNG tồn tại thật; Ruby chạy tới
  # `method_missing` khi lookup thất bại trong toàn bộ ancestors.
  module Reader
    def method_missing(name, *args, &block)
      key = flag_key(name)
      return super if key.nil? # QUAN TRỌNG: không biết thì để Ruby ném NoMethodError

      value = @flags.fetch(key)
      name.end_with?("?") ? value == true : value
    end

    # PHẢI đi cặp với method_missing, cùng điều kiện, để respond_to? và method(:x)
    # trả lời đúng. Thiếu cái này, thư viện dựa vào duck typing sẽ xử lý sai object.
    def respond_to_missing?(name, include_private = false)
      !flag_key(name).nil? || super
    end

    private

    # :new_checkout? -> :new_checkout nếu có trong flags, ngược lại nil
    def flag_key(name)
      key = name.to_s.delete_suffix("?").to_sym
      key if @flags&.key?(key)
    end
  end

  class Dynamic
    include Reader # đặt method_missing trong module: dùng lại được, nhìn `ancestors` là thấy

    def initialize(flags) = @flags = flags.transform_keys(&:to_sym)
  end

  # Cách 2: tập flag biết trước -> định nghĩa method THẬT. Nên ưu tiên cách này:
  # IDE gợi ý được, grep được, nhanh hơn, respond_to? tự đúng mà không cần code thêm.
  class Defined
    def initialize(flags)
      flags.each do |key, value|
        define_singleton_method(key) { value }
        define_singleton_method(:"#{key}?") { value == true }
      end
    end
  end
end
