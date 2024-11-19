require 'rails_helper'

RSpec.describe ProcessOrderBatchInsertJob, type: :job do
  let(:batch) do
    [
      { user_id: 1, order_id: 123, product_id: 456, name: "User1", amount: 100.5, purchase_date: Date.today, created_at: Time.now, updated_at: Time.now },
      { user_id: 2, order_id: 124, product_id: 457, name: "User2", amount: 200.5, purchase_date: Date.today, created_at: Time.now, updated_at: Time.now }
    ]
  end

  subject { described_class.perform_now(batch) }

  it "inserts all records in the batch" do
    expect { subject }.to change(Order, :count).by(2)
  end

  it "logs a success message for the batch" do
    allow(Rails.logger).to receive(:info)
    described_class.perform_now(batch)
    expect(Rails.logger).to have_received(:info).with(/Batch processed successfully/)
  end

  it "retries unique records on duplicate error" do
    allow(Order).to receive(:insert_all).and_raise(ActiveRecord::RecordNotUnique)
    allow(Rails.logger).to receive(:info)

    expect { described_class.perform_now(batch) }.not_to raise_error
    expect(Rails.logger).to have_received(:info).with(/Retrying with 2 unique records.../)
  end

  context "with duplicate records" do
    before do
      Order.create!(batch.first)
    end

    it "ignores duplicate records" do
      expect { subject }.to change(Order, :count).by(1)
    end

    it "logs an error when duplicate records are detected" do
      allow(Order).to receive(:insert_all).and_raise(ActiveRecord::RecordNotUnique)
      allow(Rails.logger).to receive(:error).with(/Duplicate records detected/)

      subject

      expect(Rails.logger).to have_received(:error).with(/Duplicate records detected/).twice
    end
  end

end
