require 'rails_helper'

RSpec.describe "Rack::Attack Throttling", type: :request do
  let(:valid_file) { fixture_file_upload('test_file.txt', 'text/plain') }
  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  describe "GET /orders" do
    let(:path) { '/orders' }

    it "allows up to the limit of requests per minute" do
      5.times do
        get path
        expect(response).to have_http_status(:success)
      end
    end

    it "blocks requests exceeding the limit" do
      5.times { get path }
      get path

      expect(response).to have_http_status(:too_many_requests)
      expect(JSON.parse(response.body)['message']).to eq("Rate limit exceeded. Try again later.")
    end
  end

  describe "POST /orders/upload" do
    let(:path) { '/orders/upload' }

    it "allows up to the limit of requests per minute" do
      5.times do
        post path, params: { file: valid_file }
        expect(response).to have_http_status(:success).or have_http_status(:accepted)
      end
    end

    it "blocks requests exceeding the limit" do
      5.times { post path }
      post path

      expect(response).to have_http_status(:too_many_requests)
      expect(JSON.parse(response.body)['message']).to eq("Rate limit exceeded. Try again later.")
    end
  end
end
