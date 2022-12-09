module Spree
  class StripeCustomer < Spree::Base
    acts_as_paranoid

    belongs_to :user, class_name: Spree.user_class.to_s

    has_many :stripe_subscriptions,
             class_name: 'Spree::StripeSubscription',
             foreign_key: :customer_id,
             inverse_of: :customer,
             dependent: :restrict_with_error
    has_many :stripe_invoices,
             class_name: 'Spree::StripeInvoice',
             foreign_key: :customer_id,
             inverse_of: :customer,
             dependent: :restrict_with_error

    def stripe_customer
      stripe_customer = nil
      return nil if deleted_at.present?

      stripe_customer = Stripe::Customer.retrieve(stripe_customer_id)
    rescue StandardError
      destroy
      stripe_customer = nil
    ensure
      stripe_customer
    end
  end
end
