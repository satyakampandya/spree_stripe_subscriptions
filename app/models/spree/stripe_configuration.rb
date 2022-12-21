module Spree
  class StripeConfiguration < Spree::Base
    acts_as_paranoid

    preference :secret_key, :string
    preference :public_key, :string
    preference :webhook_secret, :string

    ADDRESS_COLLECTION_OPTIONS = {
      'auto' => 'auto',
      'required' => 'required'
    }.freeze

    validates :billing_address_collection, inclusion: { in: ADDRESS_COLLECTION_OPTIONS.keys }

    has_many :stripe_plans,
             class_name: 'Spree::StripePlan',
             foreign_key: :configuration_id,
             inverse_of: :configuration,
             dependent: :restrict_with_error

    scope :active, -> { where(active: true) }

    def preferred_keys_available?
      preferred_secret_key.present? && preferred_public_key.present? && preferred_webhook_secret.present?
    end
  end
end
