require 'stripe'
require 'stripe_tester' if Rails.env.development? || Rails.env.test?

Stripe.api_version = '2020-03-02'

begin
  Stripe.api_key = Spree::StripeConfiguration.active.last&.preferred_secret_key
rescue ActiveRecord::StatementInvalid => e
  Rails.logger.error e
  # Ignored
end
