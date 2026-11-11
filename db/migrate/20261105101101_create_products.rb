class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.decimal :price, precision: 12, scale: 2, null: false
      t.integer :stock, null: false, default: 0
      t.integer :lock_version, null: false, default: 0 # optimistic locking
      t.timestamps
    end
    # DB là authority: stock không bao giờ âm, dù app có bug
    add_check_constraint :products, "stock >= 0", name: "products_stock_non_negative"
    add_check_constraint :products, "price >= 0", name: "products_price_non_negative"
  end
end
