class AddIdempotencyKeyToPayments < ActiveRecord::Migration[8.0]
  def change
    # Bước 1: Thêm column, tạm thời cho phép NULL
    add_column :payments, :idempotency_key, :string

    # Bước 2: Tạo key cho các payment cũ
    execute <<~SQL
      UPDATE payments
      SET idempotency_key = 'legacy_payment_' || id::text
      WHERE idempotency_key IS NULL
    SQL

    # Bước 3: Bắt buộc phải có idempotency_key
    change_column_null :payments, :idempotency_key, false

    # Bước 4: Không cho phép trùng key
    add_index :payments, :idempotency_key, unique: true
  end
end
