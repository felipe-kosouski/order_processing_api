class OrdersController < ApplicationController
  def index
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
end
