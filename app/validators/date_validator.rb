class DateValidator
  def self.validate!(date, field)
    raise InvalidDateFormatError, "#{field} has an invalid date format" unless valid_date_format?(date)
  end

  private

  def self.valid_date_format?(date)
    Date.strptime(date, "%Y-%m-%d")
    true
  rescue ArgumentError
    false
  end
end
