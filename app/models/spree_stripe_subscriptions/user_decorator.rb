# frozen_string_literal: true

module SpreeStripeSubscriptions
  module UserDecorator
    def self.prepended(base)
      base.has_many :stripe_customers,
                    class_name: 'Spree::StripeCustomer',
                    foreign_key: :user_id,
                    inverse_of: :user,
                    dependent: :restrict_with_error
      base.has_many :stripe_subscriptions,
                    class_name: 'Spree::StripeSubscription',
                    foreign_key: :user_id,
                    inverse_of: :user,
                    dependent: :restrict_with_error
      base.has_many :stripe_subscription_events,
                    class_name: 'Spree::StripeSubscriptionEvent',
                    foreign_key: :user_id,
                    inverse_of: :user,
                    dependent: :restrict_with_error
      base.has_many :stripe_invoices,
                    class_name: 'Spree::StripeInvoice',
                    foreign_key: :user_id,
                    inverse_of: :user,
                    dependent: :restrict_with_error
    end

    def probable_name
      name = email[/[^@]+/]
      name.split('.').map(&:capitalize).join(' ')
    end

    def find_or_create_stripe_customer
      current_customer = stripe_customers.last
      stripe_customer = current_customer&.stripe_customer
      return stripe_customer if stripe_customer

      stripe_customer = Stripe::Customer.create(
        email: email,
        name: probable_name,
        metadata: { user_id: id }
      )
      stripe_customers.create(stripe_customer_id: stripe_customer.id)

      stripe_customer
    end
  end
end

Spree::User.prepend SpreeStripeSubscriptions::UserDecorator if Spree::User.included_modules.exclude?(SpreeStripeSubscriptions::UserDecorator)
