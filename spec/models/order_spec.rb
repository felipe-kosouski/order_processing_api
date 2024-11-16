require 'rails_helper'

RSpec.describe Order, type: :model do
  describe "validations" do
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:order_id) }
    it { should validate_presence_of(:product_id) }
    it { should validate_presence_of(:amount) }
    it { should validate_presence_of(:purchase_date) }

    it { should validate_numericality_of(:user_id).only_integer }
    it { should validate_numericality_of(:order_id).only_integer }
    it { should validate_numericality_of(:product_id).only_integer }
    it { should validate_numericality_of(:amount) }
  end
end
