class CartsController < ApplicationController
  def show
    return render status: 422, json: { error: I18n.t('cart.id_not_sent') } if session[:cart_id].blank?

    @cart = Cart.find_by(id: session[:cart_id])
    render status: 404, json: { error: I18n.t('cart.not_found', id: session[:cart_id]) } if @cart.blank?
  end

  def create
    @cart = Cart.find_or_initialize_by(id: session[:cart_id])
    response.status = 201 unless @cart.persisted?
    @cart.add_item(**item_params.to_h.symbolize_keys)
    session[:cart_id] = @cart.id
  end

  def destroy
    @cart = Cart.find_by(id: session[:cart_id])
    unless @cart.remove_product(params[:product_id])
      return render status: :not_found, json: { error: I18n.t('product.not_found', id: params[:product_id]) }
    end
  end

  def add_item
    @cart = Cart.find_by(id: session[:cart_id])
    @cart.add_item(**item_params.to_h.symbolize_keys)
  end

  private

  def item_params
    params.permit(:product_id, :quantity)
  end
end
