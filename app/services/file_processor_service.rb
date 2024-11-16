class FileProcessorService
  def initialize(file)
    @file = file
  end

  def process
    File.foreach(@file.path, chomp: true) do |line|
      parse_and_save(line)
    end
  end

  private

  def parse_and_save(line)
    parsed_data = parse_line(line)
    Order.create(parsed_data)
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
  end
end
