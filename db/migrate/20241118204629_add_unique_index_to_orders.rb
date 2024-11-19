class AddUniqueIndexToOrders < ActiveRecord::Migration[7.2]
  def change
    add_index :orders, [ :user_id, :order_id, :product_id ], unique: true
  end
end
