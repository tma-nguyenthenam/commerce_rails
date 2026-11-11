class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :idempotency_key, null: false
      t.decimal :total, precision: 12, scale: 2, null: false, default: 0
      t.datetime :confirmation_sent_at
      t.timestamps
    end
    # Chặn đơn trùng khi client retry
    add_index :orders, :idempotency_key, unique: true
  end
end
