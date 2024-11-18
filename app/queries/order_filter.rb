class OrderFilter
  def initialize(params, orders)
    @params = params
    @orders = orders
  end

  def call
    validate_dates!
    apply_filters
    @orders
  end

  private

  def apply_filters
    filter_by_order_id
    filter_by_date_range
  end

  def filter_by_order_id
    @orders = @orders.where(order_id: @params[:order_id]) if @params[:order_id].present?
  end

  def filter_by_date_range
    return unless @params[:start_date].present?

    start_date = Date.parse(@params[:start_date])
    end_date = @params[:end_date].present? ? Date.parse(@params[:end_date]) : Date.current
    @orders = @orders.where(purchase_date: start_date..end_date)
  end

  def validate_dates!
    %i[start_date end_date].each do |date_param|
      DateValidator.validate!(@params[date_param], date_param.to_s) if @params[date_param].present?
    end
  end
end
