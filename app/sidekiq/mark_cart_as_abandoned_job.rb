class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform(*args)
    abandoned_carts = Cart.where(last_interaction_at: ..3.hours.ago)
    abandoned_carts.find_each do |cart|
      removed = cart.remove_if_abandoned
      next if removed

      cart.mark_as_abandoned
    end
  end
end
