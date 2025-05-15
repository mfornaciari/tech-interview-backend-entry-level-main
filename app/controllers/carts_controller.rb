class CartsController < ApplicationController
  before_action :validate_cart_id, only: %i[show destroy add_item]
  before_action :validate_product, only: %i[create add_item]
  before_action :validate_quantity, only: %i[create add_item]
  before_action :find_existing_cart, only: %i[show destroy add_item]

  rescue_from StandardError, with: :render_generic_error

  def show; end

  def create
    @cart = Cart.find_or_initialize_by(id: session[:cart_id])
    response.status = 201 unless @cart.persisted?
    @cart.add_item!(**item_params)
    session[:cart_id] = @cart.id
  end

  def destroy
    item = @cart.cart_items.find_by(product_id: params[:product_id])
    if item.blank?
      return render status: :not_found, json: { error: I18n.t('product.not_in_cart', id: params[:product_id]) }
    end

    item.destroy!
  end

  def add_item
    @cart.add_item!(**item_params)
  end

  private

  def find_existing_cart
    @cart = Cart.find_by(id: session[:cart_id])
    render status: 404, json: { error: I18n.t('cart.not_found', id: session[:cart_id]) } if @cart.blank?
  end

  def item_params
    params.permit(:product_id, :quantity).to_h.symbolize_keys
  end

  def render_generic_error
    render status: :internal_server_error, json: { error: I18n.t('error.generic') }
  end

  def validate_cart_id
    render status: 422, json: { error: I18n.t('cart.id_not_sent') } if session[:cart_id].blank?
  end

  def validate_product
    unless Product.where(id: params[:product_id]).exists?
      render status: 404, json: { error: I18n.t('product.not_found', id: params[:product_id]) }
    end
  end

  def validate_quantity
    if params[:quantity].blank? || !params[:quantity].positive?
      render status: 422, json: { error: I18n.t('quantity.invalid', quantity: params[:quantity] )}
    end
  end
end
