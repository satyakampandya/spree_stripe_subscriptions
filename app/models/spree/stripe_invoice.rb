module Spree
  class StripeInvoice < Spree::Base
    acts_as_paranoid

    STATUS_OPTIONS = {
      'draft' => 'Draft',
      'open' => 'Open',
      'paid' => 'Paid',
      'uncollectible' => 'Uncollectible',
      'void' => 'Void'
    }.freeze

    validates :status, inclusion: { in: STATUS_OPTIONS.keys }

    belongs_to :customer, class_name: 'Spree::StripeCustomer'
    belongs_to :subscription, class_name: 'Spree::StripeSubscription'
  end
end
