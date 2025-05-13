class AddAbandonedToCarts < ActiveRecord::Migration[7.1]
  def change
    add_column :carts, :abandoned, :boolean, null: false, default: false
  end
end
