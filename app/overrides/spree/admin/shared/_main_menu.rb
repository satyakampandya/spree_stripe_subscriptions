Deface::Override.new(
  virtual_path: 'spree/admin/shared/_main_menu',
  name: 'admin_stripe_subscriptions_menu_index',
  insert_before: '[id="sidebarConfiguration"]'
) do
  <<-HTML
    <% if can? :admin, Spree::StripeConfiguration %>
      <ul class="nav nav-sidebar border-bottom" id="sidebarStripeSubscriptions">
        <%= main_menu_tree I18n.t('spree_stripe_subscriptions.admin.stripe_subscriptions'), icon: 'list.svg', sub_menu: 'stripe_subscriptions', url: '#sidebar-stripe-subscriptions' %>
      </ul>
    <% end %>
  HTML
end
