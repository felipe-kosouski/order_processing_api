class ProcessOrderBatchInsertJob < ApplicationJob
  queue_as :default

  def perform(batch)
    ActiveRecord::Base.transaction do
      insert_batch(batch)
    end
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
    Order.insert_all(batch, unique_by: [ :user_id, :order_id, :product_id ])
  end

  def handle_duplicates(batch, error)
    Rails.logger.error("Duplicate records detected: #{error.message}")

    unique_records = batch.reject do |record|
      Order.exists?(
        user_id: record[:user_id],
        order_id: record[:order_id],
        product_id: record[:product_id]
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
    ActiveRecord::Base.transaction do
      insert_batch(unique_records)
    end
    Rails.logger.info("Successfully retried and inserted #{unique_records.size} records.")
  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.error("Duplicate records detected on retry: #{e.message}")
  end
end

