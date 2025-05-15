class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  after_save :update_cart!
  after_destroy :update_cart!

  validates :quantity, numericality: { greater_than: 0 }

  def total_price
    product.price * quantity
  end

  private

  def update_cart!
    cart.update_data!
  end
end
