FactoryBot.define do
  factory :cart_item do
    cart { nil }
    product
    quantity { 1 }
  end
end
