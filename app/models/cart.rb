class Cart < ApplicationRecord
  has_many :cart_items

  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  # TODO: lógica para marcar o carrinho como abandonado e remover se abandonado
  def mark_as_abandoned
    return if last_interaction_at > 3.hours.ago

    update(abandoned: true)
  end

  def remove_if_abandoned
    return if last_interaction_at > 7.days.ago

    destroy
  end
end
