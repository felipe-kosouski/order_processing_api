require 'rails_helper'

RSpec.describe "Orders", type: :request do
  let!(:orders) do
    (1..10).map do |i|
      create(:order, purchase_date: Date.current - i.days)
    end
  end
  let(:valid_file) { fixture_file_upload('test_file.txt', 'text/plain') }

  describe "GET /orders" do
    it 'returns orders with the correct structure' do
      get '/orders'
      json_response = JSON.parse(response.body)
      expect(json_response.first.keys).to match_array(%w[user_id name orders])
      expect(json_response.first['orders'].first.keys).to match_array(%w[order_id total date products])
      expect(json_response.first['orders'].first['products'].first.keys).to match_array(%w[product_id value])
    end

    context "when filters are provided" do
      context "when filtering by order_id" do
        before { get '/orders', params: { order_id: orders.first.order_id } }

        it "returns the matching order" do
          json_response = JSON.parse(response.body)
          expect(json_response).not_to be_empty
          expect(json_response.size).to eq(1)
          expect(json_response.first['user_id']).to eq(orders.first.user_id)
          expect(json_response.first['orders'].first['order_id']).to eq(orders.first.order_id)
        end

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end
      end

      context "when filtering by date range" do
        before { get '/orders', params: { start_date: (Date.current - 4.days).to_s, end_date: (Date.current).to_s } }

        it "returns orders" do
          json_response = JSON.parse(response.body)
          expect(json_response).not_to be_empty
          expect(json_response.size).to eq(4)
        end

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end
      end
    end

    context "when no filters are provided" do
      before { get '/orders' }

      it "returns orders" do
        json_response = JSON.parse(response.body)
        expect(json_response).not_to be_empty
        expect(json_response.size).to eq(orders.size)
      end

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end
    end
  end

  describe "POST /orders/upload" do
    context "when file is provided" do

      context "when file is valid" do
        before { post '/orders/upload', params: { file: valid_file } }

        it "returns a success message" do
          json_response = JSON.parse(response.body)
          expect(json_response['message']).to eq("File processed successfully")
        end

        it "returns status code 200" do
          expect(response).to have_http_status(200)
        end
      end
    end

    context "when no file is provided" do
      before { post '/orders/upload' }

      it "returns an error message" do
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq("File not provided")
      end

      it "returns status code 422" do
        expect(response).to have_http_status(422)
      end
    end
  end
end
