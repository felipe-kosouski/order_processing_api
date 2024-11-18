require 'rails_helper'

RSpec.describe OrderFilter do
  let!(:orders) do
    (1..10).map do |i|
      create(:order, order_id: i, purchase_date: Date.strptime("2024-11-18") - i.days)
    end
  end

  subject { described_class.new(params, Order.all) }

  describe "#call" do
    context "when all parameters are valid" do
      let(:params) { { start_date: '2024-11-16', end_date: '2024-11-18', order_id: 1 } }

      it "returns filtered orders" do
        result = subject.call
        expect(result).to contain_exactly(orders.first)
      end
    end

    context "when start_date is missing" do
      let(:params) { { end_date: '2024-11-18' } }

      it "returns orders up to the current date" do
        result = subject.call
        expect(result).to contain_exactly(*orders)
      end
    end

    context "when start_date is missing and order_id is present" do
      let(:params) { { end_date: '2024-11-18', order_id: 1 } }

      it "returns order with matching id" do
        result = subject.call
        expect(result).to contain_exactly(orders.first)
      end
    end

    context "when end_date is missing" do
      let(:params) { { start_date: '2024-11-16' } }
      it "returns orders from the start_date to the current date" do
        result = subject.call
        expect(result).to contain_exactly(*orders[0..1])
      end
    end

    context "when end_date is missing and order_id is present" do
      let(:params) { { start_date: '2024-11-16', order_id: 1 } }

      it "returns order with matching id" do
        result = subject.call
        expect(result).to contain_exactly(orders.first)
      end
    end

    context "when order_id is missing" do
      let(:params) { { start_date: '2024-11-08', end_date: '2024-11-18' } }
      it "returns orders within the date range" do
        result = subject.call
        expect(result).to contain_exactly(*orders)
      end
    end

    context "when no parameters are provided" do
      let(:params) { {} }

      it "returns all orders" do
        result = subject.call
        expect(result).to contain_exactly(*orders)
      end
    end
  end

  describe "#validate_dates!" do
    context "when dates are valid" do
      let(:params) { { start_date: '2024-01-01', end_date: '2024-12-31' } }

      it "does not raise an error" do
        expect { subject.send(:validate_dates!) }.not_to raise_error
      end
    end

    context "when start_date is invalid" do
      let(:params) { { start_date: 'invalid_date', end_date: '2023-12-31' } }

      it "raises an InvalidDateFormatError" do
        expect { subject.send(:validate_dates!) }.to raise_error(InvalidDateFormatError, "start_date has an invalid date format")
      end
    end

    context "when end_date is invalid" do
      let(:params) { { start_date: '2023-01-01', end_date: 'invalid_date' } }

      it "raises an InvalidDateFormatError" do
        expect { subject.send(:validate_dates!) }.to raise_error(InvalidDateFormatError, "end_date has an invalid date format")
      end
    end
  end
end
