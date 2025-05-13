class ChangeTotalPriceOnCart < ActiveRecord::Migration[7.1]
  def change
    change_column_null :carts, :total_price, false
    change_column_default :carts, :total_price, 0.0
  end
end
