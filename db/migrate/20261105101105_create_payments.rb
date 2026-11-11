class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :external_id
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.timestamps
    end
    add_index :payments, :external_id, unique: true
  end
end
