require 'rails_helper'

RSpec.describe "Orders", type: :request do
  let!(:orders) do
    (1..10).map do |i|
      create(:order, purchase_date: Date.current - i.days)
    end
  end
  let(:valid_file) { fixture_file_upload('test_file.txt', 'text/plain') }
  let(:malformed_file) { fixture_file_upload('malformed_test_file.txt', 'text/plain') }
  let(:empty_file) { fixture_file_upload('empty_test_file.txt', 'text/plain') }

  describe "GET /orders" do
    let(:path) { '/orders' }

    context "with pagination" do
      it "returns paginated orders" do
        get path, params: { page: 1, per_page: 5 }
        expect(json_response.size).to eq(5)
      end

      it "includes pagination metadata in headers" do
        get path, params: { page: 1, per_page: 10 }

        expect(response).to have_http_status(:ok)

        expect(response.headers).to have_key('current-page')
        expect(response.headers).to have_key('page-items')
        expect(response.headers).to have_key('total-pages')
        expect(response.headers).to have_key('total-count')
        expect(response.headers).to have_key('link')
      end
    end

    it 'returns orders with the correct structure' do
      get path
      expect(json_response.first.keys).to match_array(%w[user_id name orders])
      expect(json_response.first['orders'].first.keys).to match_array(%w[order_id total date products])
      expect(json_response.first['orders'].first['products'].first.keys).to match_array(%w[product_id value])
    end

    context "when filters are provided" do
      context "when filtering by order_id" do
        before { get path, params: { order_id: orders.first.order_id } }

        context "when the order_id exists" do
          it "returns the matching order" do
            expect(json_response).not_to be_empty
            expect(json_response.size).to eq(1)
            expect(json_response.first['user_id']).to eq(orders.first.user_id)
            expect(json_response.first['orders'].first['order_id']).to eq(orders.first.order_id)
          end

          it "returns status code 200" do
            expect(response).to have_http_status(200)
          end
        end

        context "when the order_id does not exist" do
          before { get path, params: { order_id: 1234567890 } }

          it "returns an empty array" do
            expect(json_response).to be_empty
          end

          it "returns status code 200" do
            expect(response).to have_http_status(200)
          end
        end
      end

      context "when filtering by date range" do
        context "when date range is valid" do
          before { get path, params: { start_date: (Date.current - 4.days).to_s, end_date: (Date.current).to_s } }

          it "returns orders" do
            expect(json_response).not_to be_empty
            expect(json_response.size).to eq(4)
          end

          it "returns status code 200" do
            expect(response).to have_http_status(200)
          end
        end

        context "when date range is invalid" do
          context "when start_date is invalid" do
            subject { get path, params: { start_date: 'invalid', end_date: (Date.current - 4.days).to_s } }

            it "returns an error message" do
              subject
              expect(json_response['message']).to eq("start_date has an invalid date format")
            end

            it "returns status code 422" do
              subject
              expect(response).to have_http_status(422)
            end
          end

          context "when end_date is invalid" do
            subject { get path, params: { start_date: (Date.current - 4.days).to_s, end_date: 'invalid' } }

            it "returns an error message" do
              subject
              expect(json_response['message']).to eq("end_date has an invalid date format")
            end

            it "returns status code 422" do
              subject
              expect(response).to have_http_status(422)
            end
          end
        end

        context "when end_date is missing" do
          before { get path, params: { start_date: (Date.current - 4.days).to_s } }

          it "returns orders" do
            expect(json_response).not_to be_empty
            expect(json_response.size).to eq(4)
          end

          it "returns status code 200" do
            expect(response).to have_http_status(200)
          end
        end

        context "when no orders are found within the date range" do
          before { get path, params: { start_date: (Date.current + 1.day).to_s, end_date: (Date.current + 2.days).to_s } }

          it "returns an empty array" do
            expect(json_response).to be_empty
          end

          it "returns status code 200" do
            expect(response).to have_http_status(200)
          end
        end
      end
    end

    context "when no filters are provided" do
      before { get path }

      it "returns orders" do
        expect(json_response).not_to be_empty
        expect(json_response.size).to eq(orders.size)
      end

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end
    end
  end

  describe "POST /orders/upload" do
    let(:path) { '/orders/upload' }

    context "when file is provided" do
      context "when file is valid" do
        before { post path, params: { file: valid_file } }

        it "returns a success message" do
          expect(json_response['message']).to eq("File processed successfully")
        end

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end
      end

      context "when file is malformed" do
        it "does not create any orders" do
          expect { post path, params: { file: malformed_file } }.not_to change { Order.count }
        end

        it "returns a success message" do
          post path, params: { file: malformed_file }
          expect(json_response['message']).to eq("File processed successfully")
        end

        it "returns status code 200" do
          post path, params: { file: malformed_file }
          expect(response).to have_http_status(200)
        end
      end

      context "when file is empty" do
        it "does not create any orders" do
          expect { post path, params: { file: empty_file } }.not_to change { Order.count }
        end

        it "returns a success message" do
          post path, params: { file: empty_file }
          expect(json_response['message']).to eq("File processed successfully")
        end

        it "returns status code 200" do
          post path, params: { file: empty_file }
          expect(response).to have_http_status(200)
        end
      end

      context "when the file has an invalid format" do
        let(:invalid_format_file) { fixture_file_upload('invalid_format_file.csv', 'text/csv') }

        it "returns an error" do
          post path, params: { file: invalid_format_file }
          expect(json_response['message']).to eq("Error processing file: Invalid file format")
        end
      end

      context "when the file contains duplicate orders" do
        let(:duplicate_file) { fixture_file_upload('duplicate_test_file.txt', 'text/plain') }

        it "creates only unique orders" do
          expect { post path, params: { file: duplicate_file } }.to change { Order.count }.by(1)
        end
      end
    end

    context "when no file is provided" do
      before { post path }

      it "returns an error message" do
        expect(json_response['message']).to eq("File not provided")
      end

      it "returns status code 422" do
        expect(response).to have_http_status(422)
      end
    end
  end
end
