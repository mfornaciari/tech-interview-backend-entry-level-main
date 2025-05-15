require 'rails_helper'

describe CartsController, type: :controller do
  render_views

  describe '#show' do
    subject(:get_request) { get :show, as: :json }

    context 'when cart exists' do
      let(:cart) { create(:shopping_cart) }
      let(:product) { create(:product, name: 'Product', price: 10.0) }

      before do
        session[:cart_id] = cart.id
        create(:cart_item, cart: cart, product: product, quantity: 3)
      end

      it 'returns cart data' do
        expected_response = {
          id: cart.id,
          products: [
            {
              id: product.id,
              name: 'Product',
              quantity: 3,
              unit_price: '10.0',
              total_price: '30.0'
            }
          ],
          total_price: '30.0'
        }.to_json

        get_request

        expect(response.status).to eq(200)
        expect(response.body).to match(expected_response)
      end
    end

    context 'when cart does not exist' do
      before { session[:cart_id] = 1 }

      it 'returns 404 and an error message' do
        get_request

        expect(response.status).to eq(404)
        expect(response.body).to eq({ error: "Cart 1 not found" }.to_json)
      end
    end

    context 'when session does not have cart_id' do
      it 'returns 422 and an error message' do
        get_request

        expect(response.status).to eq(422)
        expect(response.body).to eq({ error: "No cart ID sent" }.to_json)
      end
    end
  end

  describe '#create' do
    subject(:post_request) { post :create, params: { product_id: product_id, quantity: quantity }, as: :json }

    let(:product) { create(:product) }

    before { freeze_time }

    context 'when product ID is valid' do
      let(:product_id) { product.id }

      context 'and quantity is not valid' do
        let(:quantity) { -1 }

        it 'returns 422 and an error message' do
          travel_to(1.second.ago) do
            expect { post_request }.to not_change(Cart, :count).and not_change(CartItem, :count)
          end

          expect(response.status).to eq(422)
          expect(response.body).to eq({ error: "Quantity #{quantity} is invalid" }.to_json)
        end
      end

      context 'and quantity is valid' do
        let(:quantity) { 2 }

        context 'and cart does not exist' do
          it 'creates cart, adds cart ID to session and returns correct response' do
            travel_to(1.second.ago) do
              expect { post_request }.to change(Cart, :count).from(0).to(1)
            end

            created_cart = Cart.last
            expect(created_cart.last_interaction_at).to eq(1.second.ago)
            expect(created_cart.cart_items)
              .to contain_exactly(an_object_having_attributes(product_id: product.id, quantity: 2))
            expect(session[:cart_id]).to eq(created_cart.id)
            expect(response.status).to eq 201
            expected_response = {
              id: created_cart.id,
              products: [
                {
                  id: product.id,
                  name: 'Product',
                  quantity: 2,
                  unit_price: '10.0',
                  total_price: '20.0'
                }
              ],
              total_price: '20.0'
            }.to_json
            expect(response.body).to eq(expected_response)
          end
        end

        context 'and cart already exists' do
          let(:cart) { create(:shopping_cart) }
          let!(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 1) }

          before { session[:cart_id] = cart.id }

          it 'updates existing cart' do
            travel_to(1.second.ago) do
              expect { post_request }.not_to change(Cart, :count)
            end

            expect(cart.reload.last_interaction_at).to eq(1.second.ago)
            expect(cart.cart_items)
              .to contain_exactly(an_object_having_attributes(product_id: product.id, quantity: 3))
            expect(session[:cart_id]).to eq(cart.id)
            expect(response.status).to eq 200
            expected_response = {
              id: cart.id,
              products: [
                {
                  id: product.id,
                  name: 'Product',
                  quantity: 3,
                  unit_price: '10.0',
                  total_price: '30.0'
                }
              ],
              total_price: '30.0'
            }.to_json
            expect(response.body).to eq(expected_response)
          end
        end

        context 'and an error happens' do
          before do
            cart = Cart.new
            allow(Cart).to receive(:find_or_initialize_by).and_return(cart)
            allow(cart).to receive(:add_item!).and_raise(StandardError)
          end

          it 'returns 500 and an error message' do
            travel_to(1.second.ago) do
              expect { post_request }.to not_change(Cart, :count).and not_change(CartItem, :count)
            end

            expect(session[:cart_id]).to be_nil
            expect(response.status).to eq 500
            expect(response.body).to eq({ error: 'An error happened. Please try again' }.to_json)
          end
        end
      end
    end

    context 'when product ID is not valid' do
      let(:product_id) { product.id + 1 }
      let(:quantity) { 2 }

      it 'returns 404 and an error message' do
        travel_to(1.second.ago) do
          expect { post_request }.to not_change(Cart, :count).and not_change(CartItem, :count)
        end

        expect(response.status).to eq(404)
        expect(response.body).to eq({ error: "Product #{product_id} not found" }.to_json)
      end
    end
  end

  describe '#destroy' do
    subject(:delete_request) { delete :destroy, params: { product_id: product.id } }

    let(:cart) { create(:shopping_cart) }
    let(:product) { create(:product) }

    before { freeze_time }

    context 'when session has cart_id' do
      before { session[:cart_id] = cart_id }

      context 'and cart exists' do
        let(:cart_id) { cart.id }

        context 'and the product is in the cart' do
          let!(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 2) }

          context 'and no errors happen' do
            it 'removes product from cart and returns correct response' do
              expected_response = {
                id: cart.id,
                products: [],
                total_price: '0.0'
              }.to_json

              travel_to(1.second.ago) { delete_request }

              expect(cart.reload.last_interaction_at).to eq(1.second.ago)
              expect(cart.cart_items).to be_empty
              expect(response.status).to eq(200)
              expect(response.body).to eq(expected_response)
            end
          end

          context 'and removing the item fails' do
            before do
              allow(Cart).to receive(:find_by).with(id: cart_id).and_return(cart)
              allow(cart.cart_items).to receive(:find_by).with(product_id: product.id.to_s).and_return(cart_item)
              allow(cart_item).to receive(:destroy!).and_raise(StandardError)
            end

            it 'returns 500 and an error message' do
              travel_to(1.second.ago) { delete_request }

              expect(cart.reload.last_interaction_at).to eq(Time.current)
              expect(cart.cart_items)
                .to contain_exactly(an_object_having_attributes(product_id: product.id, quantity: 2))
              expect(response.status).to eq(500)
              expect(response.body).to eq({ error: 'An error happened. Please try again' }.to_json)
            end
          end
        end

        context 'and the product is not in the cart' do
          let(:other_product) { create(:product, name: 'Other product' ) }
          let!(:cart_item) { create(:cart_item, cart: cart, product: other_product, quantity: 2) }

          it 'returns 404 and an error message' do
            travel_to(1.second.ago) { delete_request }

            expect(cart.reload.last_interaction_at).to eq(Time.current)
            expect(cart.cart_items).to contain_exactly(cart_item)
            expect(response.status).to eq(404)
            expect(response.body).to eq({ error: "Product #{product.id} not found in cart" }.to_json)
          end
        end
      end

      context 'and cart does not exist' do
        let(:cart_id) { cart.id + 1 }

        it 'returns 404 and an error message' do
          travel_to(1.second.ago) do
            expect { delete_request }.not_to change(CartItem, :count)
          end

          expect(cart.reload.last_interaction_at).to eq(Time.current)
          expect(response.status).to eq(404)
          expect(response.body).to eq({ error: "Cart #{cart_id} not found" }.to_json)
        end
      end
    end

    context 'when session does not have cart_id' do
      it 'returns 422 and an error message' do
        travel_to(1.second.ago) do
          expect { delete_request }.not_to change(CartItem, :count)
        end

        expect(cart.reload.last_interaction_at).to eq(Time.current)
        expect(response.status).to eq(422)
        expect(response.body).to eq({ error: "No cart ID sent" }.to_json)
      end
    end
  end

  describe '#add_item' do
    subject(:post_request) { post :add_item, params: { product_id: product_id, quantity: quantity }, as: :json}

    let(:cart) { create(:shopping_cart) }
    let(:product) { create(:product, name: 'Product', price: 10.0) }

    before { freeze_time }

    context 'when session has cart_id' do
      before { session[:cart_id] = cart_id }

      context 'and product_id is valid' do
        let(:product_id) { product.id}

        context 'and quantity is not valid' do
          let(:quantity) { '' }
          let(:cart_id) { cart.id }

          it 'returns 422 and an error message' do
            travel_to(1.second.ago) do
              expect { post_request }.to not_change(CartItem, :count)
            end

            expect(response.status).to eq(422)
            expect(response.body).to eq({ error: "Quantity #{quantity} is invalid" }.to_json)
          end
        end

        context 'and quantity is valid' do
          let(:quantity) { 2 }

          context 'and cart exists' do
            let(:cart_id) { cart.id }

            context 'and product is in the cart' do
              before { create(:cart_item, cart: cart, product: product, quantity: 1) }

              it 'updates cart without creating new cart item and returns correct response' do
                travel_to(1.second.ago) do
                  expect { post_request }.not_to change(cart.cart_items, :count)
                end

                expect(cart.reload.last_interaction_at).to eq(1.second.ago)
                expect(cart.cart_items)
                  .to contain_exactly(an_object_having_attributes(product_id: product.id, quantity: 3))
                expect(response.status).to eq(200)
                expected_response = {
                  id: cart.id,
                  products: [
                    {
                      id: product.id,
                      name: 'Product',
                      quantity: 3,
                      unit_price: '10.0',
                      total_price: '30.0'
                    }
                  ],
                  total_price: '30.0'
                }.to_json
                expect(response.body).to eq(expected_response)
              end
            end

            context 'and product is not in the cart' do
              let(:other_product) { create(:product, name: 'Other product', price: 5.0) }

              before { create(:cart_item, cart: cart, product: other_product, quantity: 1) }

              it 'creates new cart item and returns correct response' do
                travel_to(1.second.ago) do
                  expect { post_request }.to change(cart.cart_items, :count).from(1).to(2)
                end

                expect(cart.reload.last_interaction_at).to eq(1.second.ago)
                expect(cart.cart_items)
                  .to contain_exactly(
                    an_object_having_attributes(product_id: other_product.id, quantity: 1),
                    an_object_having_attributes(product_id: product.id, quantity: 2),
                  )
                expect(response.status).to eq(200)
                expected_response = {
                  id: cart.id,
                  products: [
                    {
                      id: other_product.id,
                      name: 'Other product',
                      quantity: 1,
                      unit_price: '5.0',
                      total_price: '5.0'
                    },
                    {
                      id: product.id,
                      name: 'Product',
                      quantity: 2,
                      unit_price: '10.0',
                      total_price: '20.0'
                    },
                  ],
                  total_price: '25.0'
                }.to_json
                expect(response.body).to eq(expected_response)
              end
            end

            context 'and an error happens' do
              before do
                allow(Cart).to receive(:find_by).and_return(cart)
                allow(cart).to receive(:add_item!).and_raise(StandardError)
              end

              it 'returns 500 and an error message' do
                travel_to(1.second.ago) do
                  expect { post_request }.to not_change(Cart, :count).and not_change(CartItem, :count)
                end

                expect(session[:cart_id]).to eq(cart_id)
                expect(response.status).to eq 500
                expect(response.body).to eq({ error: 'An error happened. Please try again' }.to_json)
              end
            end
          end

          context 'and cart does not exist' do
            let(:cart_id) { cart.id + 1 }

            it 'returns 404 and an error message' do
              travel_to(1.second.ago) do
                expect { post_request }.not_to change(CartItem, :count)
              end

              expect(cart.reload.last_interaction_at).to eq(Time.current)
              expect(response.status).to eq(404)
              expect(response.body).to eq({ error: "Cart #{cart_id} not found" }.to_json)
            end
          end
        end
      end

      context 'and product_id is not valid' do
        let(:product_id) { product.id + 1 }
        let(:cart_id) { cart.id }
        let(:quantity) { 2 }

        it 'returns 404 and an error message' do
          travel_to(1.second.ago) do
            expect { post_request }.to not_change(Cart, :count).and not_change(CartItem, :count)
          end

          expect(response.status).to eq(404)
          expect(response.body).to eq({ error: "Product #{product_id} not found" }.to_json)
        end
      end
    end

    context 'when session does not have cart_id' do
      let(:product_id) { product.id }
      let(:quantity) { 2 }

      it 'returns 422 and an error message' do
        travel_to(1.second.ago) do
          expect { post_request }.not_to change(CartItem, :count)
        end

        expect(cart.reload.last_interaction_at).to eq(Time.current)
        expect(response.status).to eq(422)
        expect(response.body).to eq({ error: "No cart ID sent" }.to_json)
      end
    end
  end
end
