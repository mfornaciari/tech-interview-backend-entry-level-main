class CartsController < ApplicationController
  before_action :validate_cart_id, only: %i[show destroy add_item]
  before_action :validate_product, only: %i[create add_item]
  before_action :find_existing_cart, only: %i[show destroy add_item]

  def show; end

  def create
    @cart = Cart.find_or_initialize_by(id: session[:cart_id])
    response.status = 201 unless @cart.persisted?
    @cart.add_item(**item_params.to_h.symbolize_keys)
    session[:cart_id] = @cart.id
  end

  def destroy
    unless @cart.remove_product(params[:product_id])
      return render status: :not_found, json: { error: I18n.t('product.not_in_cart', id: params[:product_id]) }
    end
  end

  def add_item
    @cart.add_item(**item_params.to_h.symbolize_keys)
  end

  private

  def find_existing_cart
    @cart = Cart.find_by(id: session[:cart_id])
    render status: 404, json: { error: I18n.t('cart.not_found', id: session[:cart_id]) } if @cart.blank?
  end

  def item_params
    params.permit(:product_id, :quantity)
  end

  def validate_cart_id
    render status: 422, json: { error: I18n.t('cart.id_not_sent') } if session[:cart_id].blank?
  end

  def validate_product
    unless Product.where(id: params[:product_id]).exists?
      render status: 404, json: { error: I18n.t('product.not_found', id: params[:product_id]) }
    end
  end
end
