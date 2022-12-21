module Spree
  class StripePlan < Spree::Base
    acts_as_paranoid

    acts_as_list column: :weightage

    INTERVAL = { day: 'Daily', week: 'Weekly', month: 'Monthly', year: 'Annually' }.freeze
    CURRENCY = { usd: 'USD', gbp: 'GBP', jpy: 'JPY', eur: 'EUR', aud: 'AUD', hkd: 'HKD', sek: 'SEK', nok: 'NOK', dkk: 'DKK', pen: 'PEN',
                 cad: 'CAD' }.freeze

    TAX_BEHAVIOUR_OPTIONS = {
      'inclusive' => 'inclusive',
      'exclusive' => 'exclusive',
      'unspecified' => 'unspecified'
    }.freeze

    validates :tax_behavior, inclusion: { in: TAX_BEHAVIOUR_OPTIONS.keys }
    validates :configuration, presence: true

    belongs_to :configuration, class_name: 'Spree::StripeConfiguration'

    has_many :stripe_subscriptions,
             class_name: 'Spree::StripeSubscription',
             foreign_key: :plan_id,
             inverse_of: :plan,
             dependent: :restrict_with_error

    before_validation :set_stripe_plan_id, on: :create

    after_create :create_plan
    after_update :update_plan
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

    def update_price_tax_behavior
      Stripe::Price.update(stripe_plan_id, { tax_behavior: tax_behavior })
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
      if plan.present?
        update_price_tax_behavior
      end
    rescue StandardError
      plan = nil
    ensure
      plan
    end

    def update_plan
      update_price_tax_behavior if tax_behavior_previously_changed?
      return unless name_previously_changed?

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
