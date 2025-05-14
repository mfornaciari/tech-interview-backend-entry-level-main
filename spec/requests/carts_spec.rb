require 'rails_helper'

RSpec.describe "/carts", type: :request do
  # Apesar das instruções solicitarem a não alteração de testes existentes, foi necessário alterar o teste abaixo,
  # visto que 1) as instruções indicam que a rota deve se chamar "/cart/add_item", não "/cart/add_items" e
  # 2) as instruções indicam que o carrinho é identificado por sessão, mas as requisições não têm dados de sessão.
  # Tentei restringir as modificações ao mínimo necessário.
  describe "POST /add_items" do
    let(:cart) { create :shopping_cart }
    let(:product) { Product.create(name: "Test Product", price: 10.0) }
    let!(:cart_item) { CartItem.create(cart: cart, product: product, quantity: 1) }

    context 'when the product already is in the cart' do
      subject do
        sign_in cart.user
        post '/cart/add_item', params: { product_id: product.id, quantity: 1 }, as: :json
        sign_in cart.user
        post '/cart/add_item', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      it 'updates the quantity of the existing item in the cart' do
        expect { subject }.to change { cart_item.reload.quantity }.by(2)
      end

      it 'returns correct response' do
        expected_response = {
          id: cart.id,
          products: [
            {
              id: product.id,
              name: product.name,
              quantity: 3,
              unit_price: product.price,
              total_price: product.price * 3
            }
          ],
          total_price: product.price * 3
        }.to_json

        sign_in cart.user
        post '/cart/add_item', params: { product_id: product.id, quantity: 2 }, as: :json

        expect(response.body).to eq expected_response
      end
    end

    context 'when the product is not in the cart' do
      let(:new_product) { create(:product, name: "Other Test Product") }

      subject do
        sign_in cart.user
        post '/cart/add_item', params: { product_id: new_product.id, quantity: 2 }, as: :json
      end

      it 'adds product to cart and returns correct response' do
        expected_response = {
          id: cart.id,
          products: [
            {
              id: product.id,
              name: product.name,
              quantity: cart_item.quantity,
              unit_price: product.price,
              total_price: product.price
            },
            {
              id: new_product.id,
              name: new_product.name,
              quantity: 2,
              unit_price: new_product.price,
              total_price: new_product.price * 2
            }
          ],
          total_price: product.price + (new_product.price * 2)
        }.to_json

        subject

        expect(cart.reload.cart_items).to contain_exactly(
          an_object_having_attributes(**cart_item.attributes),
          an_object_having_attributes(product_id: new_product.id, quantity: 2)
        )
        expect(response.body).to eq expected_response
      end
    end
  end
end
