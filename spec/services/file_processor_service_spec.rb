require 'rails_helper'

RSpec.describe FileProcessorService, type: :service do
  let(:valid_file) { fixture_file_upload('test_file.txt', 'text/plain') }
  let(:large_file) { fixture_file_upload('large_test_file.txt', 'text/plain') }

  describe "#process" do
    it "calls save_batch when batch size is reached" do
      service = FileProcessorService.new(large_file)
      allow(service).to receive(:save_batch).and_call_original
      service.process
      expect(service).to have_received(:save_batch).at_least(:once)
    end

    it "logs an error when an exception occurs while processing a line" do
      service = FileProcessorService.new(valid_file)
      allow(service).to receive(:parse_line).and_raise(StandardError, "Test error")
      expect(Rails.logger).to receive(:error).with(/Error processing line \d+: Test error/).twice
      service.process
    end

    it "continues processing lines even when a batch contains duplicates" do
      service = FileProcessorService.new(valid_file)
      allow(Order).to receive(:insert_all).and_raise(ActiveRecord::RecordNotUnique, "Duplicate records")
      expect(Rails.logger).to receive(:error).with(/Duplicate records detected/)
      expect { service.process }.not_to raise_error
    end
  end
end
