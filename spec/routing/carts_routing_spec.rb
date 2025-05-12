require "rails_helper"

RSpec.describe CartsController, type: :routing do
  describe 'routes' do
    it 'routes to #show' do
      expect(get: '/cart').to route_to('carts#show')
    end

    it 'routes to #create' do
      pending "#TODO: Escreva um teste para validar a criação de um carrinho #{__FILE__}" 
    end

    it 'routes to #add_item via POST' do
      expect(post: '/cart/add_item').to route_to('carts#add_item')
    end
  end
end 
