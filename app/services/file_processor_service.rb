class FileProcessorService
  def initialize(file)
    @file = file
  end

  def process
    raise "Invalid file format" unless valid_file_format?

    File.foreach(@file.path, chomp: true).with_index do |line, index|
      next if line.strip.empty?
      begin
        parse_and_save(line)
      rescue StandardError => e
        Rails.logger.error("Error processing line #{index + 1}: #{e.message}")
        next
      end
    end
  end

  private

  def valid_file_format?
    @file.content_type == "text/plain"
  end

  def parse_and_save(line)
    parsed_data = parse_line(line)
    Order.find_or_create_by!(
      user_id: parsed_data[:user_id],
      order_id: parsed_data[:order_id],
      product_id: parsed_data[:product_id]
    ) do |order|
      order.attributes = parsed_data
    end
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
