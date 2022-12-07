module Spree
  class StripeSubscriptionsController < StoreController
    before_action :login_required
    before_action :check_if_subscription_exists, only: :create
    before_action :load_stripe_plan
    before_action :ensure_stripe_plan_exist
    before_action :ensure_stripe_customer_exist
    before_action :load_subscription, only: :destroy

    def create
      checkout_session = Stripe::Checkout::Session.create(
        mode: 'subscription',
        customer: @stripe_customer.id,
        client_reference_id: spree_current_user.id,
        line_items: [
          {
            'price': @stripe_plan.id,
            'quantity': 1
          }
        ],
        success_url: stripe_plans_url,
        cancel_url: stripe_plans_url
      )
      redirect_to checkout_session.url
    rescue StandardError => e
      Rails.logger.error e.message
      flash[:error] = e.message
      redirect_to stripe_plans_path
    end

    def destroy
      @subscription.cancel_renewal
      flash[:alert] = I18n.t('spree_stripe_subscriptions.messages.success.successfully_canceled_renewal')
      redirect_to stripe_plans_path
    end

    private

    def login_required
      raise CanCan::AccessDenied if spree_current_user.blank?
    end

    def load_stripe_plan
      @plan = Spree::StripePlan.active.find(params[:stripe_plan_id])
    end

    def check_if_subscription_exists
      return unless spree_current_user.stripe_subscriptions.active.exists?

      flash[:alert] = I18n.t('spree_stripe_subscriptions.messages.errors.already_subscribed')
      redirect_to stripe_plans_path
    end

    def ensure_stripe_customer_exist
      @stripe_customer = spree_current_user.find_or_create_stripe_customer
    end

    def ensure_stripe_plan_exist
      @stripe_plan = @plan.find_or_create_stripe_plan
      raise CanCan::AccessDenied if @stripe_plan.nil?
    end

    def load_subscription
      @subscription = @plan.stripe_subscriptions.find(params[:id])
    end
  end
end
