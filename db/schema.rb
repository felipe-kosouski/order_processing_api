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

ActiveRecord::Schema[7.2].define(version: 2024_11_18_204629) do
  create_table "orders", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.integer "order_id", null: false
    t.integer "product_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.date "purchase_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_orders_on_order_id"
    t.index ["product_id"], name: "index_orders_on_product_id"
    t.index ["purchase_date"], name: "index_orders_on_purchase_date"
    t.index ["user_id", "order_id", "product_id"], name: "index_orders_on_user_id_and_order_id_and_product_id", unique: true
  end
end
