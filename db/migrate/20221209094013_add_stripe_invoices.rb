class AddStripeInvoices < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_stripe_invoices, if_not_exists: true do |t|
      t.references :customer
      t.references :subscription

      t.string :stripe_invoice_id

      t.string :status
      t.boolean :paid, default: false
      t.string :currency

      t.decimal :amount_paid, precision: 8, scale: 2, null: false, default: 0.0
      t.decimal :subtotal, precision: 8, scale: 2, null: false, default: 0.0
      t.decimal :subtotal_excluding_tax, precision: 8, scale: 2, null: false, default: 0.0
      t.decimal :tax, precision: 8, scale: 2, null: false, default: 0.0
      t.decimal :total, precision: 8, scale: 2, null: false, default: 0.0
      t.decimal :total_excluding_tax, precision: 8, scale: 2, null: false, default: 0.0

      t.string :customer_name
      t.string :billing_reason
      t.string :invoice_pdf

      t.datetime :period_start
      t.datetime :period_end

      t.text :raw_data

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
