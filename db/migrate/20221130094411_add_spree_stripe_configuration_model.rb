class AddSpreeStripeConfigurationModel < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_stripe_configurations, if_not_exists: true do |t|
      t.string :name
      t.text :description

      t.boolean :active
      t.text :preferences

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
