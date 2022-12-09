class AddUserToInvoice < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stripe_invoices, :user_id, :bigint, if_not_exists: true
  end
end
