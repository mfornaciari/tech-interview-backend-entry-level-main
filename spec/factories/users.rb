FactoryBot.define do
  factory :user do
    email { 'user@email.com' }
    password { 'abcd1234' }
    cart { nil }
  end
end
