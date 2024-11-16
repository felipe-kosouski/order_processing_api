class Order < ApplicationRecord
  validates :user_id, :name, :order_id, :product_id, :amount, :purchase_date, presence: true
  validates :user_id, :order_id, :product_id, numericality: { only_integer: true }
  validates :amount, numericality: true
end
