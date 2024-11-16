class OrderSerializer
  def initialize(items)
    @items = items
  end

  def as_json(*)
    {
      order_id: order_id,
      total: total,
      date: date,
      products: products
    }
  end

  private

  def order_id
    @items.first.order_id
  end

  def total
    @items.sum(&:amount).to_s
  end

  def date
    @items.first.purchase_date.strftime("%Y-%m-%d")
  end

  def products
    @items.map do |item|
      ProductSerializer.new(item).as_json
    end
  end
end
