module Spree
  class StripeSubscriptionsController < StoreController
    before_action :login_required
    before_action :load_stripe_plan
    before_action :load_stripe_configuration
    before_action :ensure_stripe_plan_exist
    before_action :ensure_stripe_customer_exist
    before_action :load_stripe_subscription, only: [:update, :destroy, :change_payment_details, :update_payment_details]
    before_action :ensure_active_subscription, only: :downgrade

    def create
      checkout_session = Stripe::Checkout::Session.create(
        mode: 'subscription',
        customer: @stripe_customer.id,
        customer_update: { address: 'auto', name: 'auto' },
        client_reference_id: spree_current_user.id,
        line_items: [
          {
            'price': @stripe_plan.id,
            'quantity': 1
          }
        ],
        allow_promotion_codes: @configuration.allow_promotion_codes,
        automatic_tax: { enabled: @configuration.automatic_tax },
        tax_id_collection: { enabled: @configuration.tax_id_collection },
        billing_address_collection: @configuration.billing_address_collection,
        success_url: stripe_plans_url,
        cancel_url: stripe_plans_url
      )
      redirect_to checkout_session.url
    rescue StandardError => e
      Rails.logger.error e.message
      flash[:error] = e.message
      redirect_to stripe_plans_path
    end

    def update
      @subscription.cancel_renewal
      flash[:success] = I18n.t('spree_stripe_subscriptions.messages.success.successfully_canceled_renewal')
      redirect_to stripe_plans_path
    end

    def change_payment_details
      checkout_session = Stripe::Checkout::Session.create(
        payment_method_types: ['card'],
        mode: 'setup',
        customer: @stripe_customer.id,
        setup_intent_data: {
          metadata: {
            subscription_id: @subscription.stripe_subscription_id
          }
        },
        success_url: "#{update_payment_details_stripe_plan_stripe_subscription_url(@plan, @subscription)}?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: stripe_plans_url
      )
      redirect_to checkout_session.url
    rescue StandardError => e
      Rails.logger.error e.message
      flash[:error] = e.message
      redirect_to stripe_plans_path
    end

    def update_payment_details
      return unless (session_id = params[:session_id])

      checkout_session = Stripe::Checkout::Session.retrieve(session_id)
      setup_intent = Stripe::SetupIntent.retrieve(checkout_session.setup_intent)

      # Set invoice_settings.default_payment_method on the Customer
      Stripe::Customer.update(
        @stripe_customer.id,
        { invoice_settings: { default_payment_method: setup_intent.payment_method } }
      )

      # Set default_payment_method on the Subscription
      Stripe::Subscription.update(
        @subscription.stripe_subscription_id,
        {
          default_payment_method: setup_intent.payment_method
        }
      )

      flash[:success] = I18n.t('spree_stripe_subscriptions.messages.success.successfully_updated')
      redirect_to stripe_plans_path
    rescue StandardError => e
      Rails.logger.error e.message
      flash[:error] = e.message
      redirect_to stripe_plans_path
    end

    def downgrade
      active_subscription = spree_current_user.stripe_subscriptions.active.find(params[:id])
      destination_plan = Spree::StripePlan.active.find(params[:stripe_plan_id])

      subscription_schedule = active_subscription.stripe_subscription_schedule

      if subscription_schedule.present?
        Stripe::SubscriptionSchedule.update(
          subscription_schedule.id,
          {
            phases: [
              {
                items: [
                  { price: active_subscription.plan.stripe_plan_id, quantity: 1 }
                ],
                start_date: active_subscription.current_period_start.to_i,
                end_date: active_subscription.current_period_end.to_i
              },
              {
                items: [
                  { price: destination_plan.stripe_plan_id, quantity: 1 }
                ],
                start_date: active_subscription.current_period_end.to_i,
                # end_date: active_subscription.current_period_end.to_i + 1.month.to_i
              }
            ]
          }
        )
        flash[:success] = I18n.t('spree_stripe_subscriptions.messages.success.successfully_downgraded')
        redirect_to stripe_plans_path
      else
        flash[:alert] = I18n.t('spree_stripe_subscriptions.messages.errors.cannot_process_request')
        redirect_to stripe_plans_path
      end
    end

    def destroy
      @subscription.unsubscribe
      flash[:success] = I18n.t('spree_stripe_subscriptions.messages.success.successfully_unsubscribed')
      redirect_to stripe_plans_path
    end

    private

    def login_required
      raise CanCan::AccessDenied if spree_current_user.blank?
    end

    def load_stripe_plan
      @plan = Spree::StripePlan.active.find(params[:stripe_plan_id])
    end

    def load_stripe_configuration
      @configuration = @plan.configuration
    end

    def ensure_active_subscription
      return if spree_current_user.stripe_subscriptions.active.exists?

      flash[:alert] = I18n.t('spree_stripe_subscriptions.messages.errors.no_active_subscription')
      redirect_to stripe_plans_path
    end

    def ensure_stripe_customer_exist
      @stripe_customer = spree_current_user.find_or_create_stripe_customer
    end

    def ensure_stripe_plan_exist
      @stripe_plan = @plan.find_or_create_stripe_plan
      raise CanCan::AccessDenied if @stripe_plan.nil?
    end

    def load_stripe_subscription
      @subscription = @plan.stripe_subscriptions.find(params[:id])
    end
  end
end
