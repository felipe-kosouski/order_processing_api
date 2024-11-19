class FileProcessorService
  BATCH_SIZE = 1000

  def initialize(file)
    @file = file
  end

  def process
    raise "Invalid file format" unless valid_file_format?

    batch = []
    File.foreach(@file.path, chomp: true).with_index do |line, index|
      next if line.strip.empty?
      begin
        batch << parse_line(line)
        if batch.size >= BATCH_SIZE
          save_batch(batch)
          batch.clear
        end
      rescue StandardError => e
        Rails.logger.error("Error processing line #{index + 1}: #{e.message}")
        next
      end
    end
    save_batch(batch) unless batch.empty?
  end

  private

  def save_batch(batch)
    begin
      Order.insert_all(batch, unique_by: [ :user_id, :order_id, :product_id ])
    rescue ActiveRecord::RecordNotUnique => e
      Rails.logger.error("Duplicate records detected: #{e.message}")
    end
  end

  def valid_file_format?
    @file.content_type == "text/plain"
  end

  def parse_line(line)
    {
      user_id: line[0..9].strip.to_i,
      name: line[10..54].strip,
      order_id: line[55..64].strip.to_i,
      product_id: line[65..74].strip.to_i,
      amount: line[75..86].strip.to_f,
      purchase_date: Date.strptime(line[87..94].strip, "%Y%m%d")
    }
  rescue ArgumentError => e
    raise "Malformed data: #{e.message}"
  end
end
