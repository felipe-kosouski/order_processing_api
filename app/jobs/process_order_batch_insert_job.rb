class ProcessOrderBatchInsertJob < ApplicationJob
  queue_as :default

  def perform(batch)
    inserted_count = insert_batch(batch)
    Rails.logger.info("Successfully inserted #{inserted_count} records.")
  rescue ActiveRecord::RecordNotUnique => e
    handle_duplicates(batch, e)
  rescue StandardError => e
    Rails.logger.error("Error processing batch: #{e.message}")
    raise e
  else
    Rails.logger.info("Batch processed successfully with #{batch.size} records.")
  end

  private

  def insert_batch(batch)
    ActiveRecord::Base.transaction do
      result = Order.insert_all(batch, unique_by: [ :user_id, :order_id, :product_id ])
      result.count
    end
  end

  def handle_duplicates(batch, error)
    Rails.logger.error("Duplicate records detected: #{error.message}")

    unique_records = batch.reject do |record|
      Order.find_by(
        user_id: record[:user_id].to_i,
        order_id: record[:order_id].to_i,
        product_id: record[:product_id].to_i
      )
    end

    if unique_records.any?
      Rails.logger.info("Retrying with #{unique_records.size} unique records...")
      retry_insert(unique_records)
    else
      Rails.logger.warn("No unique records left to process in the batch.")
    end
  end

  def retry_insert(unique_records)
    retried_count = insert_batch(unique_records)
    Rails.logger.info("Successfully retried and inserted #{retried_count} records.")
  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.error("Duplicate records detected on retry: #{e.message}")
  end
end
