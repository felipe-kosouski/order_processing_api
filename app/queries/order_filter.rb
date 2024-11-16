class OrderFilter
  def initialize(params, orders)
    @params = params
    @orders = orders
  end

  def call
    filter_by_order_id
    filter_by_date_range
    @orders
  end

  private

  def filter_by_order_id
    @orders = @orders.where(order_id: @params[:order_id]) if @params[:order_id].present?
  end

  def filter_by_date_range
    return unless @params[:start_date].present?

    start_date = Date.parse(@params[:start_date])
    end_date = @params[:end_date].present? ? Date.parse(@params[:end_date]) : Date.current
    @orders = @orders.where(purchase_date: start_date..end_date)
  end
end
