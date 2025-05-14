require 'rails_helper'

RSpec.describe "/carts", type: :request do
  describe 'GET /cart' do
    subject(:get_request) do
      sign_in user
      get '/cart', as: :json
    end

    let(:user) { create(:user) }
    let(:cart) { create(:shopping_cart, user: user) }
    let!(:cart_item1) { create(:cart_item, cart: cart, product: product1, quantity: 2) }
    let!(:cart_item2) { create(:cart_item, cart: cart, product: product2, quantity: 3) }
    let(:product1) { create(:product, name: 'Product', price: 5.0) }
    let(:product2) { create(:product, name: 'Other product', price: 10.0) }

    it 'returns correct response' do
      expected_response = {
        id: cart.id,
        products: [
          {
            id: product1.id,
            name: 'Product',
            quantity: 2,
            unit_price: '5.0',
            total_price: '10.0'
          },
          {
            id: product2.id,
            name: 'Other product',
            quantity: 3,
            unit_price: '10.0',
            total_price: '30.0'
          },
        ],
        total_price: '40.0'
      }.to_json

      get_request

      expect(response.body).to eq expected_response
    end
  end

  describe 'POST /cart' do
    subject(:post_request) do
      sign_in user
      post '/cart', params: params, as: :json
    end

    let(:user) { create(:user) }
    let(:params) { { product_id: product.id, quantity: 2 } }
    let(:product) { create(:product) }

    context 'when the cart does not exist' do
      it 'creates cart and returns correct response' do
        post_request

        expected_response = {
          id: user.cart.id,
          products: [
            {
              id: product.id,
              name: product.name,
              quantity: 2,
              unit_price: product.price,
              total_price: product.price * 2
            }
          ],
          total_price: product.price * 2
        }.to_json
        expect(user.cart).to be_persisted
        expect(user.cart.cart_items).to contain_exactly(an_object_having_attributes(**params))
        expect(response.body).to eq(expected_response)
      end
    end

    context 'when the cart already exists' do
      let(:cart) { create(:shopping_cart, user: user) }

      before { create(:cart_item, cart: cart, product: product, quantity: 1) }

      it 'updates cart item and returns correct response' do
        post_request

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
        expect(user.cart).to be_persisted
        expect(user.cart.cart_items)
          .to contain_exactly(an_object_having_attributes(product_id: product.id, quantity: 3))
        expect(response.body).to eq(expected_response)
      end
    end
  end

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

        expect(response.body).to eq(expected_response)
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

        expect(cart.cart_items).to contain_exactly(
          an_object_having_attributes(**cart_item.attributes),
          an_object_having_attributes(product_id: new_product.id, quantity: 2)
        )
        expect(response.body).to eq(expected_response)
      end
    end
  end
end
