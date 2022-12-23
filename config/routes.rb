Spree::Core::Engine.add_routes do
  namespace :admin, path: Spree.admin_path do
    resources :stripe_configurations, except: :show do
      resources :stripe_plans, except: :show do
        collection do
          post :update_positions
        end
      end
    end

    resources :stripe_customers, only: :index
    resources :stripe_subscriptions, only: :index
    resources :stripe_subscription_events, only: :index
  end

  resources :stripe_plans, only: :index, path: SpreeStripeSubscriptions::Config.stripe_plans_path do
    resources :stripe_subscriptions, only: %i[create update destroy] do
      post :downgrade, on: :member
      post :change_payment_details, on: :member
      get :update_payment_details, on: :member
    end
  end

  resources :stripe_webhooks, only: :none, path: SpreeStripeSubscriptions::Config.stripe_webhooks_path do
    post :handler, on: :collection
  end
end
