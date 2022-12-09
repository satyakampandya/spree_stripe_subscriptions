class AddSchedulesToSubscription < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stripe_subscriptions, :schedule, :string
    add_column :spree_stripe_subscriptions, :next_plan_id, :bigint
  end
end
