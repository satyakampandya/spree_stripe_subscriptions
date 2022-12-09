module Spree
  class StripePlansController < StoreController
    before_action :load_active_plans, only: :index
    before_action :load_user_subscriptions, only: :index

    def index; end

    private

    def load_active_plans
      @stripe_plans = Spree::StripePlan.active.order(:weightage)
    end

    def load_user_subscriptions
      @active_subscription = if spree_current_user.present?
                               spree_current_user.stripe_subscriptions.active.last
                             end
    end
  end
end
