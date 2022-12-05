class AddSpreeStripeSubscriptionEventsModel < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_stripe_subscription_events, if_not_exists: true do |t|
      t.string :event_id
      t.string :event_type

      t.references :subscription
      t.references :user

      t.text :response

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
