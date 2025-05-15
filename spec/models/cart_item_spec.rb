require 'rails_helper'
RSpec.describe CartItem, type: :model do
  it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0) }
end
