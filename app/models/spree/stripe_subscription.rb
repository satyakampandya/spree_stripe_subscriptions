module Spree
  class StripeSubscription < Spree::Base
    acts_as_paranoid

    belongs_to :plan, class_name: 'Spree::StripePlan'
    belongs_to :customer, class_name: 'Spree::StripeCustomer'
    belongs_to :user, class_name: Spree.user_class.to_s

    has_many :stripe_subscription_events,
             class_name: 'Spree::StripeSubscriptionEvent',
             foreign_key: :subscription_id,
             inverse_of: :subscription,
             dependent: :restrict_with_error

    STATUS_OPTIONS = {
      'incomplete' => 'Incomplete',
      'incomplete_expired' => 'Incomplete Expired',
      'trialing' => 'Trialing',
      'active' => 'Active',
      'past_due' => 'Past Due',
      'canceled' => 'Canceled',
      'unpaid' => 'Unpaid'
    }.freeze

    validates :status, inclusion: { in: STATUS_OPTIONS.keys }

    scope :active, -> { where(status: 'active') }

    def cancel_renewal
      Stripe::Subscription.update(
        stripe_subscription_id,
        { cancel_at_period_end: true }
      )
    rescue StandardError => e
      Rails.logger.error e
    end

    def register_webhook_event(event)
      stripe_subscription_events.create(
        event_id: event.id,
        event_type: event.type,
        user: user,
        response: event.to_json
      )
    end
  end
end
