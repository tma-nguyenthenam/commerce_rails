class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 12, scale: 2, null: false
      t.timestamps
    end
    add_check_constraint :order_items, "quantity > 0", name: "order_items_quantity_positive"
  end
end
