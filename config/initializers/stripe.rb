require 'stripe'
require 'stripe_tester' if Rails.env.development? || Rails.env.test?

Stripe.api_version = '2018-02-28'

begin
  Stripe.api_key = Spree::StripeConfiguration.active.last&.preferred_secret_key
rescue ActiveRecord::StatementInvalid => e
  Rails.logger.error e
  # Ignored
end
