class CartsController < ApplicationController
  def add_item
    @item = current_user.cart.add_item(**item_params.to_h.symbolize_keys)
  end

  private

  def item_params
    params.permit(:product_id, :quantity)
  end
end
