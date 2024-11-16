class ProductSerializer

  def initialize(product)
    @product = product
  end

  def as_json(*)
    {
      product_id: @product.product_id,
      value: @product.amount.to_s
    }
  end
end
