class CartsController < ApplicationController
  def show
    @cart = current_user.cart
  end

  def create
    @cart = current_user.cart.present? ? current_user.cart : current_user.build_cart
    @cart.add_item(**item_params.to_h.symbolize_keys)
  end

  def destroy
    @cart = current_user.cart
    unless @cart.remove_product(params[:product_id])
      return render status: :not_found, json: { error: I18n.t('product.not_found', id: params[:product_id]) }
    end
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
