FactoryBot.define do
  factory :shopping_cart, class: 'Cart' do
    total_price { 100.00 }
    last_interaction_at { Time.current }
  end
end
