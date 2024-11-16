class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.integer :user_id, null: false
      t.string :name, null: false
      t.integer :order_id, null: false
      t.integer :product_id, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :purchase_date, null: false

      t.timestamps
    end

    add_index :orders, :order_id
    add_index :orders, :product_id
    add_index :orders, :purchase_date
  end
end
