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
    subject
    expect(Rails.logger).to have_received(:info).with(/Batch processed successfully/)
  end

  it "logs an error when a standard error occurs" do
    allow(Order).to receive(:insert_all).and_raise(StandardError.new("Some error"))
    allow(Rails.logger).to receive(:error)

    expect { subject }.to raise_error(StandardError)
    expect(Rails.logger).to have_received(:error).with(/Error processing batch: Some error/)
  end

  context "when duplicated records are detected" do
    before do
      Order.create!(batch.first)
    end

    it "ignores duplicate records" do
      expect { subject }.to change(Order, :count).by(1)
    end

    it "logs an error" do
      allow(Order).to receive(:insert_all).and_raise(ActiveRecord::RecordNotUnique)
      allow(Rails.logger).to receive(:error).with(/Duplicate records detected/)

      subject

      expect(Rails.logger).to have_received(:error).with(/Duplicate records detected/).twice
    end

    context "when no unique records are left to process" do
      before do
        Order.create!(batch.last)
      end

      it "logs a warning" do
        allow(Order).to receive(:insert_all).and_raise(ActiveRecord::RecordNotUnique)
        allow(Rails.logger).to receive(:warn)

        subject

        expect(Rails.logger).to have_received(:warn).with(/No unique records left to process in the batch/).once
      end
    end

    # it "successfully retries and inserts unique records" do
    #   allow(Order).to receive(:insert_all).and_raise(ActiveRecord::RecordNotUnique).once
    #   allow(Order).to receive(:insert_all).and_call_original
    #   allow(Rails.logger).to receive(:info)
    #
    #   subject
    #   # expect { subject }.to change(Order, :count).by(1)
    #   expect(Rails.logger).to have_received(:info).with(/Successfully retried and inserted 1 records/)
    # end
    #
    # it "retries unique records on duplicate error" do
    #   allow(Order).to receive(:insert_all).and_raise(ActiveRecord::RecordNotUnique)
    #   allow(Rails.logger).to receive(:info)
    #
    #   expect { subject }.not_to raise_error
    #   expect(Rails.logger).to have_received(:info).with(/Retrying with 2 unique records.../)
    # end

    # it "logs an error when duplicate records are detected on retry" do
    #   allow(Order).to receive(:insert_all).and_raise(ActiveRecord::RecordNotUnique)
    #   allow(Rails.logger).to receive(:error).with(/Duplicate records detected on retry/)
    #
    #   described_class.perform_now(batch)
    #
    #   expect(Rails.logger).to have_received(:error).with(/Duplicate records detected on retry/)
    # end
  end

end
