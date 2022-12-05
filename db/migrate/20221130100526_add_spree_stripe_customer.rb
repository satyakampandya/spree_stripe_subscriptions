class AddSpreeStripeCustomer < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_stripe_customers, if_not_exists: true do |t|
      t.references :user
      t.string :stripe_customer_id

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
