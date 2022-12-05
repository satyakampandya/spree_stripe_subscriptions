class AddSpreeStripePlanModel < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_stripe_plans, if_not_exists: true do |t|
      t.string :name
      t.text :description

      t.string :currency
      t.decimal :amount, precision: 8, scale: 2, null: false, default: 0.0

      t.string :interval
      t.integer :interval_count, default: 1
      t.integer :trial_period_days, default: 0

      t.references :configuration
      t.string :stripe_plan_id, null: false

      t.boolean :active, default: false

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
