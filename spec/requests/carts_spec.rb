require 'rails_helper'

RSpec.describe "/carts", type: :request do
  pending "TODO: Escreva os testes de comportamento do controller de carrinho necessários para cobrir a sua implmentação #{__FILE__}"

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
    end
  end
end
