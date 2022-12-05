module Spree
  module Admin
    class StripePlansController < Spree::Admin::ResourceController
      before_action :load_strip_configuration

      def new
        @stripe_plan = @stripe_configuration.stripe_plans.build
      end

      def collection
        super.reorder(:weightage)
      end

      def collection_url
        spree.admin_stripe_configuration_stripe_plans_url(@stripe_configuration)
      end

      def new_object_url
        spree.new_admin_stripe_configuration_stripe_plan_url(@stripe_configuration)
      end

      private

      def stripe_configuration
        @stripe_configuration ||= Spree::StripeConfiguration.where(id: params[:stripe_configuration_id]).first
      end

      def load_strip_configuration
        return if stripe_configuration

        flash[:error] = I18n.t('spree_stripe_subscriptions.errors.stripe_configuration_doesnt_exist')
        redirect_to admin_stripe_configurations_path
      end
    end
  end
end
