module Spree
  class StripeSubscription < Spree::Base
    acts_as_paranoid

    belongs_to :plan, class_name: 'Spree::StripePlan'
    belongs_to :next_plan, class_name: 'Spree::StripePlan'
    belongs_to :customer, class_name: 'Spree::StripeCustomer'
    belongs_to :user, class_name: Spree.user_class.to_s

    has_many :stripe_subscription_events,
             class_name: 'Spree::StripeSubscriptionEvent',
             foreign_key: :subscription_id,
             inverse_of: :subscription,
             dependent: :restrict_with_error
    has_many :stripe_invoices,
             class_name: 'Spree::StripeInvoice',
             foreign_key: :subscription_id,
             inverse_of: :subscription,
             dependent: :restrict_with_error

    STATUS_OPTIONS = {
      'incomplete' => 'Incomplete',
      'incomplete_expired' => 'Incomplete Expired',
      'trialing' => 'Trialing',
      'active' => 'Active',
      'past_due' => 'Past Due',
      'canceled' => 'Canceled',
      'unpaid' => 'Unpaid'
    }.freeze

    validates :status, inclusion: { in: STATUS_OPTIONS.keys }

    scope :active, -> { where(status: 'active') }

    def self.create_or_update_subscription(event)
      event_data = event.data.object

      subscription_event = %w[customer.subscription.updated customer.subscription.deleted].include?(event.type)
      invoice_event = (event.type == 'invoice.paid')
      schedule_event = (event.type == 'subscription_schedule.updated')

      stripe_subscription_id = if invoice_event || schedule_event
                                 event_data.subscription
                               elsif subscription_event
                                 event_data.id
                               end

      stripe_subscription = Stripe::Subscription.retrieve(stripe_subscription_id)

      customer = Spree::StripeCustomer.find_by!(stripe_customer_id: stripe_subscription.customer)
      plan = Spree::StripePlan.find_by!(stripe_plan_id: stripe_subscription.plan.id)

      webhook_subscription = Spree::StripeSubscription.where(
        stripe_subscription_id: stripe_subscription.id
      ).first_or_initialize

      webhook_subscription.update(
        customer: customer, user: customer.user, plan: plan, status: stripe_subscription.status,
        current_period_start: stripe_subscription.current_period_start ? Time.at(stripe_subscription.current_period_start).utc.to_datetime : nil,
        current_period_end: stripe_subscription.current_period_end ? Time.at(stripe_subscription.current_period_end).utc.to_datetime : nil,
        billing_cycle_anchor: stripe_subscription.billing_cycle_anchor ? Time.at(stripe_subscription.billing_cycle_anchor).utc.to_datetime : nil,
        cancel_at_period_end: stripe_subscription.cancel_at_period_end,
        cancel_at: stripe_subscription.cancel_at ? Time.at(stripe_subscription.cancel_at).utc.to_datetime : nil,
        canceled_at: stripe_subscription.canceled_at ? Time.at(stripe_subscription.canceled_at).utc.to_datetime : nil,
        ended_at: stripe_subscription.ended_at ? Time.at(stripe_subscription.ended_at).utc.to_datetime : nil,
        schedule: stripe_subscription.schedule
      )

      active_subscription = customer.user.stripe_subscriptions.active.last
      if active_subscription.present? && subscription_event
        # Checking if customer upgraded to other plan
        old_subscriptions = customer.user.stripe_subscriptions.active.where.not(id: [active_subscription.id, webhook_subscription.id].uniq)
        old_subscriptions.each do |old_subscription|
          # Unsubscribe from old subscription
          old_subscription.unsubscribe
        end
      end

      webhook_subscription
    end

    def self.update_subscription_schedule(event)
      event_data = event.data.object
      stripe_subscription_id = event_data.subscription

      webhook_subscription = Spree::StripeSubscription.find_by(stripe_subscription_id: stripe_subscription_id)
      if webhook_subscription.present?
        if event_data.phases.count > 1
          last_phase = event_data.phases.last
          next_plan_id = last_phase.plans.first.plan
          next_plan = Spree::StripePlan.find_by(stripe_plan_id: next_plan_id)
          if next_plan.present?
            webhook_subscription.update(next_plan_id: next_plan.id)
          end
        end
      end
      webhook_subscription
    end

    def self.create_or_update_invoice(event)
      event_data = event.data.object
      stripe_subscription_id = event_data.subscription

      webhook_subscription = Spree::StripeSubscription.find_by(stripe_subscription_id: stripe_subscription_id)

      unless webhook_subscription.present?
        # If invoice.paid webhook is sent earlier than subscription.updated then subscription will be created
        webhook_subscription = Spree::StripeSubscription.create_or_update_subscription(event)
      end

      if webhook_subscription.present?
        stripe_invoice_id = event_data.id
        customer = Spree::StripeCustomer.find_by(stripe_customer_id: event_data.customer)
        stripe_invoice = webhook_subscription.stripe_invoices.where(stripe_invoice_id: stripe_invoice_id).first_or_initialize

        period_start, period_end = if (line = event_data.lines.first)
                                     [line.period.start, line.period.end]
                                   end

        stripe_invoice.update(
          customer: customer,
          user: customer.user,
          status: event_data.status,
          paid: event_data.paid,
          currency: event_data.currency,
          amount_paid: event_data.amount_paid || 0.0,
          subtotal: event_data.subtotal || 0.0,
          subtotal_excluding_tax: event_data.subtotal_excluding_tax || 0.0,
          tax: event_data.tax || 0.0,
          total: event_data.total || 0.0,
          total_excluding_tax: event_data.total_excluding_tax || 0.0,
          customer_name: event_data.customer_name,
          billing_reason: event_data.billing_reason,
          invoice_pdf: event_data.invoice_pdf,
          period_start: period_start ? Time.at(period_start).utc.to_datetime : nil,
          period_end: period_end ? Time.at(period_end).utc.to_datetime : nil,
          raw_data: event_data
        )
      end

      webhook_subscription
    end

    def stripe_subscription_schedule
      stripe_schedule = nil
      if schedule.present?
        stripe_schedule = Stripe::SubscriptionSchedule.retrieve(schedule)
      else
        stripe_schedule = Stripe::SubscriptionSchedule.create({
                                                                from_subscription: stripe_subscription_id
                                                              })
      end
    rescue StandardError => e
      Rails.logger.error e.message
    ensure
      stripe_schedule
    end

    def cancel_renewal
      Stripe::Subscription.update(
        stripe_subscription_id,
        { cancel_at_period_end: true }
      )
    rescue StandardError => e
      Rails.logger.error e
    end

    def unsubscribe
      Stripe::Subscription.delete(
        stripe_subscription_id
      )
    rescue StandardError => e
      Rails.logger.error e
    end

    def register_webhook_event(event)
      stripe_subscription_events.create(
        event_id: event.id,
        event_type: event.type,
        user: user,
        response: event.to_json
      )
    end
  end
end
