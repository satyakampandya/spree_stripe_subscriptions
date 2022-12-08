module Spree
  class StripePlansController < StoreController
    before_action :login_required, except: :index
    before_action :load_active_plans, only: :index
    before_action :load_user_subscriptions, only: :index

    def index; end

    private

    def login_required
      raise CanCan::AccessDenied if spree_current_user.blank?
    end

    def load_active_plans
      @stripe_plans = Spree::StripePlan.active.order(:weightage)
    end

    def load_user_subscriptions
      @active_subscription = spree_current_user.stripe_subscriptions.active.last
    end
  end
end
