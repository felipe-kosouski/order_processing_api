class UserOrdersSerializer
  def initialize(user_id, orders)
    @user_id = user_id
    @orders = orders
  end

  def as_json(*)
    {
      user_id: @user_id,
      name: @orders.first.name,
      orders: orders
    }
  end

  private

  def orders
    @orders.group_by(&:order_id).map do |order_id, items|
      OrderSerializer.new(items).as_json
    end
  end
end
