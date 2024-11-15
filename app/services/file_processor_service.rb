class FileProcessorService
  def initialize(file)
    @file = file
  end

  def process
    File.foreach(@file.path, chomp: true).with_index do |line, index|
      next if index.zero?

      parse_and_save(line)
    end
  end

  private

  def parse_and_save(line)
    parsed_data = parse_line(line)
    # Save things to the database
  end

  def parse_line(line)
    {
      user_id: line[0..9].strip.to_i,
      name: line[10..54].strip,
      order_id: line[55..64].strip.to_i,
      product_id: line[65..74].strip.to_i,
      value: line[75..86].strip.to_f,
      date: Date.strptime(line[87..94].strip, "%Y%m%d")
    }
  end
end
