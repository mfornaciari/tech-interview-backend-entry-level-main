require 'rails_helper'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  subject(:run_job) { described_class.new.perform }

  context 'when there is a cart that has not been interacted with for 3 hours' do
    let!(:no_interaction_cart) { create(:shopping_cart, last_interaction_at: 3.hours.ago) }
    let!(:active_cart) { create(:shopping_cart, last_interaction_at: 179.minutes.ago) }

    it 'marks only that cart as abandoned' do
      run_job

      expect(no_interaction_cart.reload).to be_abandoned
      expect(active_cart.reload).not_to be_abandoned
    end
  end

  context 'when there is a cart that has not been interacted with for 7 days' do
    let!(:cart_to_destroy) { create(:shopping_cart, last_interaction_at: 7.days.ago) }
    let!(:abandoned_cart) { create(:shopping_cart, last_interaction_at: 167.hours.ago, abandoned: true) }

    it 'destroys only that cart as abandoned' do
      run_job

      expect(Cart.find_by(id: cart_to_destroy.id)).to be_nil
      expect(abandoned_cart.reload).to be_persisted
    end
  end
end
