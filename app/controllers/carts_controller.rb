class CartsController < ApplicationController
  def add_item
    item = current_user.cart.cart_items.find_by(product_id: params[:product_id])
    item.quantity += params[:quantity]
    item.save
  end
end
