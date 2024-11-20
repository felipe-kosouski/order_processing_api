class OrdersController < ApplicationController
  include Pagy::Backend
  after_action { pagy_headers_merge(@pagy) if @pagy }

  def index
    filtered_orders = OrderFilter.new(params, Order.all).call
    @pagy, paginated_orders = pagy(filtered_orders, limit: params[:per_page] || 10)
    grouped_orders = paginated_orders.group_by(&:user_id)

    render json: serialize_orders(grouped_orders), status: :ok
  rescue => e
    render json: { message: "#{e.message}" }, status: :unprocessable_content
  end

  def upload
    file = params[:file]
    if file.present?
      file_processor_service = FileProcessorService.new(file)
      file_processor_service.process
      render json: { message: "File processed successfully", total_lines: file_processor_service.total_lines, batch_count: file_processor_service.batch_count }, status: :ok
    else
      render json: { message: "File not provided" }, status: :unprocessable_content
    end
  rescue => e
    render json: { message: "Error processing file: #{e.message}" }, status: :unprocessable_content
  end

  private

  def serialize_orders(orders)
    orders.map { |user_id, user_orders| UserOrdersSerializer.new(user_id, user_orders).as_json }
  end
end
