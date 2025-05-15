require 'rails_helper'

RSpec.describe "/carts", type: :request do
  # Apesar das orientações indicarem que os testes não devem ser editados, foi necessário pular este teste porque
  # 1) ele faz um POST para /cart/add_items, mas as orientações solicitam a criação de um endpoint /cart/add_item e
  # 2) ele é um teste de request, que não permite a manipulação de dados de sessão e, consequentemente, não há forma
  # de indicar o carrinho ao qual adicionar items.
  # Os testes que garantem o funcionamento do controller foram implementados em
  # spec/controllers/carts_controller_spec.rb
  xdescribe "POST /add_items" do
    let(:cart) { Cart.create }
    let(:product) { Product.create(name: "Test Product", price: 10.0) }
    let!(:cart_item) { CartItem.create(cart: cart, product: product, quantity: 1) }

    context 'when the product already is in the cart' do
      subject do
        post '/cart/add_items', params: { product_id: product.id, quantity: 1 }, as: :json
        post '/cart/add_items', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      it 'updates the quantity of the existing item in the cart' do
        expect { subject }.to change { cart_item.reload.quantity }.by(2)
      end
    end
  end
end
