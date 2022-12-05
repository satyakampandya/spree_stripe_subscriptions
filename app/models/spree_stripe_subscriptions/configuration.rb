module SpreeStripeSubscriptions
  class Configuration < Spree::Preferences::Configuration

    # Some example preferences are shown below, for more information visit:
    # https://dev-docs.spreecommerce.org/internals/preferences

    preference :enabled, :boolean, default: true
    preference :stripe_plans_path, :string, default: 'stripe_plans'
    preference :stripe_webhooks_path, :string, default: 'stripe_webhooks'
    # preference :dark_chocolate, :boolean, default: true
    # preference :color, :string, default: 'Red'
    # preference :favorite_number, :integer
    # preference :supported_locales, :array, default: [:en]
  end
end
