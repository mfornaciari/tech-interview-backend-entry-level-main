require 'rails_helper'

RSpec.describe Cart, type: :model do
  context 'when validating' do
    it 'validates numericality of total_price' do
      cart = described_class.new(total_price: -1)
      expect(cart.valid?).to be_falsey
      expect(cart.errors[:total_price]).to include("must be greater than or equal to 0")
    end
  end

  describe '#add_item' do
    subject(:add_item) { cart.add_item(**item_params) }

    let(:cart) { create(:shopping_cart) }
    let!(:existing_cart_item) { create(:cart_item, cart: cart, product: existing_product, quantity: 1) }
    let(:existing_product) { create(:product) }

    context 'when product is not in the cart' do
      let(:new_product) { create(:product, name: 'New product') }
      let(:item_params) { { product_id: new_product.id, quantity: 2 } }

      it 'creates item' do
        result = add_item

        expect(result.attributes).to include(item_params.stringify_keys)
        expect(cart.reload.cart_items).to contain_exactly(
          an_object_having_attributes(**existing_cart_item.attributes),
          an_object_having_attributes(**item_params)
        )
      end
    end

    context 'when product is already in the cart' do
      let(:item_params) { { product_id: existing_product.id, quantity: 2 } }

      it 'updates item quantity' do
        result = add_item

        expect(result.attributes).to include(
          {
            product_id: existing_product.id,
            quantity: existing_cart_item.quantity + item_params[:quantity]
          }.stringify_keys
        )
        expect(cart.reload.cart_items).to contain_exactly(
          an_object_having_attributes(
            product_id: existing_product.id,
            quantity: existing_cart_item.quantity + item_params[:quantity]
          )
        )
      end
    end
  end

  describe 'mark_as_abandoned' do
    let(:shopping_cart) { create(:shopping_cart) }

    it 'marks the shopping cart as abandoned if inactive for a certain time' do
      shopping_cart.update(last_interaction_at: 3.hours.ago)
      expect { shopping_cart.mark_as_abandoned }.to change { shopping_cart.abandoned? }.from(false).to(true)
    end

    it 'returns true if shopping cart was marked as abandoned' do
      shopping_cart.update(last_interaction_at: 3.hours.ago)

      expect(shopping_cart.mark_as_abandoned).to be true
    end

    context 'when the shopping cart has not been inactive for long enough' do
      let(:shopping_cart) { create(:shopping_cart, last_interaction_at: 179.minutes.ago) }

      it 'does not mark the cart as abandoned' do
        expect { shopping_cart.mark_as_abandoned }.not_to change { shopping_cart.abandoned? }
      end

      it 'returns false' do
        expect(shopping_cart.mark_as_abandoned).to be false
      end
    end
  end

  describe 'remove_if_abandoned' do
    let(:shopping_cart) { create(:shopping_cart, last_interaction_at: 7.days.ago) }

    it 'removes the shopping cart if abandoned for a certain time' do
      shopping_cart.mark_as_abandoned
      expect { shopping_cart.remove_if_abandoned }.to change { Cart.count }.by(-1)
    end

    it 'returns true if cart was removed' do
      shopping_cart.mark_as_abandoned

      expect(shopping_cart.remove_if_abandoned).to be true
    end

    context 'when shopping cart has not been abandoned for long enough' do
      let(:shopping_cart) { create(:shopping_cart, last_interaction_at: 167.hours.ago, abandoned: true) }

      it 'does not remove the cart' do
        expect { shopping_cart.remove_if_abandoned }.not_to change { shopping_cart.abandoned? }
      end

      it 'returns false' do
        expect(shopping_cart.remove_if_abandoned).to be false
      end
    end
  end

  describe '#remove_product' do
    subject(:remove_product) { cart.remove_product(product.id) }

    let(:cart) { create(:shopping_cart) }
    let(:product) { create(:product) }

    context 'when given product ID matches the product_id of an associated cart item' do
      let!(:cart_item) { create(:cart_item, cart: cart, product: product) }

      it 'removes cart item and returns true' do
        result = remove_product

        expect(result).to be true
        expect(cart.cart_items).to be_empty
      end
    end

    context 'when given product ID does not match the product_id of any associated cart item' do
      let(:other_product) { create(:product, name: 'Other product') }
      let!(:cart_item) { create(:cart_item, cart: cart, product: other_product) }

      it 'does not change cart items and returns false' do
        result = remove_product

        expect(result).to be false
        expect(cart.cart_items).to contain_exactly(cart_item)
      end
    end
  end
end
