# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_11_11_085609) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "discount_codes", force: :cascade do |t|
    t.string "code", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.integer "max_uses", null: false
    t.integer "used_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_discount_codes_on_code", unique: true
    t.check_constraint "used_count <= max_uses", name: "discount_codes_within_limit"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.decimal "unit_price", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.check_constraint "quantity > 0", name: "order_items_quantity_positive"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "status", default: "pending", null: false
    t.string "idempotency_key", null: false
    t.decimal "total", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "confirmation_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["idempotency_key"], name: "index_orders_on_idempotency_key", unique: true
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.string "status", default: "pending", null: false
    t.string "external_id"
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_payments_on_external_id", unique: true
    t.index ["order_id"], name: "index_payments_on_order_id"
  end

  create_table "processed_events", force: :cascade do |t|
    t.string "external_event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_event_id"], name: "index_processed_events_on_external_event_id", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "price", precision: 12, scale: 2, null: false
    t.integer "stock", default: 0, null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.check_constraint "price >= 0::numeric", name: "products_price_non_negative"
    t.check_constraint "stock >= 0", name: "products_stock_non_negative"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "payments", "orders"
end
