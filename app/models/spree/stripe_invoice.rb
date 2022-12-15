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

    scope :paid, -> { where(status: 'paid') }

    belongs_to :customer, class_name: 'Spree::StripeCustomer'
    belongs_to :user, class_name: Spree.user_class.to_s
    belongs_to :subscription, class_name: 'Spree::StripeSubscription'
  end
end
