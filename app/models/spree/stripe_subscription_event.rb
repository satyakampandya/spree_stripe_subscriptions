module Spree
  class StripeSubscriptionEvent < Spree::Base
    acts_as_paranoid

    belongs_to :subscription, class_name: 'Spree::StripeSubscription'
    belongs_to :user, class_name: Spree.user_class.to_s

    validates :event_id, uniqueness: true
  end
end
