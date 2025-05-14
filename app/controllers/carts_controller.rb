class CartsController < ApplicationController
  def show
    @cart = current_user.cart
  end

  def create
    @cart = current_user.cart
    @cart = current_user.cart.present? ? current_user.cart : current_user.create_cart
    @cart.add_item(**item_params.to_h.symbolize_keys)
  end

  def add_item
    @cart = current_user.cart
    @cart.add_item(**item_params.to_h.symbolize_keys)
  end

  private

  def item_params
    params.permit(:product_id, :quantity)
  end
end
