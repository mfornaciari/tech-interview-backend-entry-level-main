FactoryBot.define do
  factory :shopping_cart, class: 'Cart' do
    abandoned { false }
    last_interaction_at { Time.current }
    total_price { 100.00 }
    user
  end
end
