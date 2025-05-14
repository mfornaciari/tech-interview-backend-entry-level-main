class Cart < ApplicationRecord
  belongs_to :user

  has_many :cart_items

  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  def add_item(product_id:, quantity:)
    item = cart_items.find_or_initialize_by(product_id: product_id)
    if item.quantity.present?
      item.quantity += quantity
    else
      item.quantity = quantity
    end
    item.save
    item
  end

  def mark_as_abandoned
    return if last_interaction_at > 3.hours.ago

    update(abandoned: true)
  end

  def remove_if_abandoned
    return if last_interaction_at > 7.days.ago

    destroy
  end
end
