class AddRatesToShop < ActiveRecord::Migration[8.0]
  def change
    add_column :shops, :exchange_rates, :jsonb, default: {}
    add_column :shops, :rates, :jsonb, default: {}
  end
end
