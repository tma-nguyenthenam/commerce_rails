class Product < ApplicationRecord
  has_many :order_items, dependent: :restrict_with_error
  belongs_to :category, optional: true

  # ── Bước 8: giai đoạn "ghi cả hai cột" (dual-write) ─────────────────────────
  # Trong lúc đổi tên name -> title, code cũ chỉ biết `name`, code mới chỉ biết
  # `title`. Hai cột luôn được giữ đồng bộ để cả hai phiên bản cùng chạy được.
  # Khi sang RELEASE 4 hãy bỏ callback này và thêm: self.ignored_columns += ["name"]
  before_validation :sync_title_and_name

  validates :title, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :generate_slug

  # jsonb validation: options must be a Hash
  validate :options_is_valid_hash

  private

  def sync_title_and_name
    if title_changed? && !name_changed?
      self.name = title      # code mới ghi title -> name theo sau
    elsif name_changed? && !title_changed?
      self.title = name      # code cũ ghi name -> title theo sau
    end
    self.title = name if title.blank?
    self.name = title if name.blank?
  end

  def generate_slug
    if slug.blank? && name.present?
      self.slug = name.parameterize
    elsif slug.present?
      self.slug = slug.parameterize
    end
  end

  def options_is_valid_hash
    unless options.is_a?(Hash)
      errors.add(:options, "must be a JSON object")
    end
  end
end
