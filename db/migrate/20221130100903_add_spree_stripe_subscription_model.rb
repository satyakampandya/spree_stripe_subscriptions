class AddSpreeStripeSubscriptionModel < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_stripe_subscriptions, if_not_exists: true do |t|
      t.references :plan
      t.references :customer
      t.references :user

      t.string :stripe_subscription_id

      t.string :status
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :billing_cycle_anchor
      t.boolean :cancel_at_period_end, default: false
      t.datetime :cancel_at
      t.datetime :canceled_at
      t.datetime :ended_at

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
