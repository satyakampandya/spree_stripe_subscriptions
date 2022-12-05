class AddWeightageToStripePlan < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stripe_plans, :weightage, :integer, if_not_exists: true

    # Migrate existing stripe plans
    Spree::StripePlan.with_deleted.order(:updated_at).each.with_index(1) do |stripe_plan, index|
      stripe_plan.update_column :weightage, index
    end
  end
end
