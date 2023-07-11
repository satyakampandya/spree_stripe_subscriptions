class AddPromotionFieldToConfigurations < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stripe_configurations, :allow_promotion_codes, :boolean, default: false
  end
end