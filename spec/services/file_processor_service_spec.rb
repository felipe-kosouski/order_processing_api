require 'rails_helper'

RSpec.describe FileProcessorService, type: :service do
  let(:valid_file) { fixture_file_upload('test_file.txt', 'text/plain') }
  let(:malformed_file) { fixture_file_upload('malformed_test_file.txt', 'text/plain') }
  let(:empty_file) { fixture_file_upload('empty_test_file.txt', 'text/plain') }

  describe '#process' do
    context 'when file follows the correct format' do
      it 'processes the file and create orders' do
        expect { FileProcessorService.new(valid_file).process }.to change(Order, :count).by(2)
      end
    end
  end
end
