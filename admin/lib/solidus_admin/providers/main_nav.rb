# frozen_string_literal: true

require "solidus_admin/container"
require "solidus_admin/main_nav_item"

module SolidusAdmin
  module Providers
    Container.register_provider("main_nav") do
      start do
        SolidusAdmin::Config.main_nav do |main_nav|
          main_nav.add(
            key: "orders",
            route: -> { spree.admin_orders_path },
            icon: "inbox-line",
            position: 10
          )

          main_nav
            .add(
              key: "products",
              route: :products_path,
              icon: "price-tag-3-line",
              position: 20,
              children: [
                {
                  key: "option_types",
                  route: -> { spree.admin_option_types_path },
                  position: 10
                }
              ]
            )

          main_nav.add(
            key: "promotions",
            route: -> { spree.admin_promotions_path },
            icon: "megaphone-line",
            position: 30
          )

          main_nav.add(
            key: "stock",
            route: -> { spree.admin_stock_items_path },
            icon: "stack-line",
            position: 40
          )

          main_nav.add(
            key: "users",
            route: -> { spree.admin_users_path },
            icon: "user-line",
            position: 50
          )

          main_nav.add(
            key: "settings",
            route: -> { spree.admin_stores_path },
            icon: "settings-line",
            position: 60
          )
        end

        container.register("main_nav_items") do
          Container.within_namespace("main_nav")
        end
      end
    end
  end
end