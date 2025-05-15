class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy

  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  def add_item(product_id:, quantity:)
    item = cart_items.find_or_initialize_by(product_id: product_id)
    item.quantity = item.quantity.present? ? item.quantity + quantity : quantity
    item.save
  rescue StandardError
    false
  end

  def mark_as_abandoned
    return false if last_interaction_at > 3.hours.ago

    update(abandoned: true)
  end

  def remove_if_abandoned
    return false if last_interaction_at > 7.days.ago

    destroy
    true
  end

  def remove_product(id)
    item = cart_items.find_by(product_id: id)
    return false if item.blank?

    item.destroy
    true
  end

  def update_data!
    update!(last_interaction_at: Time.current, total_price: cart_items.reload.sum(&:total_price))
  end
end
