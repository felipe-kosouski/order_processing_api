class OrdersController < ApplicationController
  def index
    filtered_orders = OrderFilter.new(params, Order.all).call
    grouped_orders = filtered_orders.group_by(&:user_id)
    render json: serialize_orders(grouped_orders), status: :ok
  end

  def upload
    file = params[:file]
    if file.present?
      FileProcessorService.new(file).process
      render json: { message: "File processed successfully" }, status: :ok
    else
      render json: { message: "File not provided" }, status: :unprocessable_content
    end
  end

  def serialize_orders(orders)
    orders.map { |user_id, user_orders| UserOrdersSerializer.new(user_id, user_orders).as_json }
  end
end
