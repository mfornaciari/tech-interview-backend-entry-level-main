class CartsController < ApplicationController
  def create
    @cart = current_user.cart
    if @cart.present?
      @cart.add_item(**item_params.to_h.symbolize_keys)
    else
      @cart = current_user.create_cart
      @cart.add_item(**item_params.to_h.symbolize_keys)
    end
  end

  def add_item
    @cart = current_user.cart
    @cart.add_item(**item_params.to_h.symbolize_keys)
    @cart.reload
  end

  private

  def item_params
    params.permit(:product_id, :quantity)
  end
end
