class AddExtraPlanFields < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stripe_plans, :tax_behavior, :string, default: 'unspecified'
    add_column :spree_stripe_configurations, :automatic_tax, :boolean, default: true
    add_column :spree_stripe_configurations, :billing_address_collection, :string
    add_column :spree_stripe_configurations, :tax_id_collection, :boolean, default: true
  end
end
