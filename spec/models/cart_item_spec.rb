require 'rails_helper'
RSpec.describe CartItem, type: :model do
  it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0) }

  describe '#total_price' do
    subject(:total_price) { cart_item.total_price }

    let(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 2)}
    let(:cart) { create(:shopping_cart) }
    let(:product) { create(:product, price: 10.0)}

    it { is_expected.to eq(20.0) }
  end
end
