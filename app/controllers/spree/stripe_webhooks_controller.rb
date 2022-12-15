# Ref: https://github.com/stripe-samples/checkout-foundations-ruby/blob/main/server.rb

module Spree
  class StripeWebhooksController < BaseController
    skip_before_action :verify_authenticity_token

    before_action :load_stripe_configuration

    respond_to :json

    def handler
      sig_header = request.env['HTTP_STRIPE_SIGNATURE']
      payload = request.body.read

      event = Stripe::Webhook.construct_event(
        payload, sig_header, @stripe_configuration.preferred_webhook_secret
      )

      if event.present? && (%w[customer.subscription.updated customer.subscription.deleted].include? event.type)
        subscription = Spree::StripeSubscription.create_or_update_subscription(event)
        subscription.register_webhook_event(event)
      elsif event.present? && (%w[subscription_schedule.updated].include? event.type)
        subscription = Spree::StripeSubscription.update_subscription_schedule(event)
        subscription.register_webhook_event(event) if subscription.present?
      elsif event.present? && (%w[invoice.paid].include? event.type)
        subscription = Spree::StripeSubscription.create_or_update_invoice(event)
        subscription.register_webhook_event(event) if subscription.present?
      else
        Rails.logger.warn "Unhandled event type: #{event&.type}"
      end

      render json: { success: true }, status: :ok
    rescue JSON::ParserError => e
      # Invalid payload
      Rails.logger.error e
      render json: { success: false }, status: :not_found
    rescue Stripe::SignatureVerificationError => e
      # invalid signature
      Rails.logger.error e
      render json: { success: false }, status: :not_found
    rescue ActiveRecord::RecordNotFound => e
      # Either StripeCustomer or StripePlan doesn't exist in our records
      Rails.logger.error e
      render json: { success: false }, status: :ok
    end

    private

    def load_stripe_configuration
      @stripe_configuration = Spree::StripeConfiguration.active.last
      return if @stripe_configuration.present? && @stripe_configuration.preferred_keys_available?

      render json: { success: false }, status: :not_found
    end
  end
end
