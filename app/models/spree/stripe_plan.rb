module Spree
  class StripePlan < Spree::Base
    acts_as_paranoid

    acts_as_list column: :weightage

    INTERVAL = { day: 'Daily', week: 'Weekly', month: 'Monthly', year: 'Annually' }.freeze
    CURRENCY = { usd: 'USD', gbp: 'GBP', jpy: 'JPY', eur: 'EUR', aud: 'AUD', hkd: 'HKD', sek: 'SEK', nok: 'NOK', dkk: 'DKK', pen: 'PEN',
                 cad: 'CAD' }.freeze

    belongs_to :configuration, class_name: 'Spree::StripeConfiguration'

    has_many :stripe_subscriptions,
             class_name: 'Spree::StripeSubscription',
             foreign_key: :plan_id,
             inverse_of: :plan,
             dependent: :restrict_with_error

    before_validation :set_stripe_plan_id, on: :create

    after_create :create_plan
    after_update :update_plan, if: :name_changed?
    after_destroy :delete_plan

    after_initialize :set_api_key

    scope :active, -> { where(active: true) }

    def find_or_create_stripe_plan
      stripe_plan = nil
      return stripe_plan unless active

      stripe_plan = Stripe::Plan.retrieve(stripe_plan_id)
    rescue StandardError
      stripe_plan = create_plan
    ensure
      stripe_plan
    end

    def create_plan
      plan = Stripe::Plan.create(
        id: stripe_plan_id,
        product: {
          name: name
        },
        currency: currency,
        amount: stripe_amount(amount),
        interval: interval,
        interval_count: interval_count,
        trial_period_days: trial_period_days
      )
    rescue StandardError
      plan = nil
    ensure
      plan
    end

    def update_plan
      stripe_plan = find_or_create_stripe_plan
      return unless stripe_plan

      stripe_plan.name = name
      stripe_plan.save
    end

    def delete_plan
      stripe_plan = find_or_create_stripe_plan
      return unless stripe_plan

      stripe_plan.delete
    end

    def create_or_update_subscription(event, customer)
      event_data = event.data.object
      stripe_subscription_id = event_data.id

      subscription = stripe_subscriptions.where(stripe_subscription_id: stripe_subscription_id).first_or_initialize

      subscription.update(
        customer: customer, user: customer.user,
        status: event_data.status,
        current_period_start: event_data.current_period_start ? Time.at(event_data.current_period_start).utc.to_datetime : nil,
        current_period_end: event_data.current_period_end ? Time.at(event_data.current_period_end).utc.to_datetime : nil,
        billing_cycle_anchor: event_data.billing_cycle_anchor ? Time.at(event_data.billing_cycle_anchor).utc.to_datetime : nil,
        cancel_at_period_end: event_data.cancel_at_period_end,
        cancel_at: event_data.cancel_at ? Time.at(event_data.cancel_at).utc.to_datetime : nil,
        canceled_at: event_data.canceled_at ? Time.at(event_data.canceled_at).utc.to_datetime : nil,
        ended_at: event_data.ended_at ? Time.at(event_data.ended_at).utc.to_datetime : nil
      )
      subscription
    end

    def stripe_amount(amount)
      (amount * 100).to_i
    end

    def set_api_key
      Stripe.api_key = configuration.preferred_secret_key if configuration
    end

    def set_stripe_plan_id
      self.stripe_plan_id = "VP-Plan-#{Time.current.to_i}"
    end
  end
end
