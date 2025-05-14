class CartsController < ApplicationController
  def add_item
    @item = current_user.cart.cart_items.find_or_initialize_by(product_id: item_params[:product_id])
    @item.quantity.present? ? @item.quantity += item_params[:quantity] : @item.quantity = item_params[:quantity]
    @item.save
  end

  private

  def item_params
    params.permit(:product_id, :quantity)
  end
end
