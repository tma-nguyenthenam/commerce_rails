class CreateDiscountCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :discount_codes do |t|
      t.string :code, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.integer :max_uses, null: false
      t.integer :used_count, null: false, default: 0
      t.timestamps
    end
    add_index :discount_codes, :code, unique: true
    add_check_constraint :discount_codes, "used_count <= max_uses", name: "discount_codes_within_limit"
  end
end
