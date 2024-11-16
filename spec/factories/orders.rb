FactoryBot.define do
  factory :order do
    user_id { Faker::Number.number(digits: 5) }
    name { Faker::Name.name }
    order_id { Faker::Number.number(digits: 10) }
    product_id { Faker::Number.number(digits: 10) }
    amount { Faker::Commerce.price }
    purchase_date { Faker::Date.backward(days: 30) }
  end
end
