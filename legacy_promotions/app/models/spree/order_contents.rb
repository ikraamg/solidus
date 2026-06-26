# frozen_string_literal: true

module Spree
  class OrderContents < Spree::SimpleOrderContents
    # Updates the order's line items with the params passed in.
    # Also runs the PromotionHandler::Cart.
    def update_cart(params)
      if order.update(params)
        unless order.completed?
          order.line_items = order.line_items.select { |li| li.quantity > 0 }
          order.check_shipments_and_restart_checkout
          # Update totals, then check if the order is eligible for any cart promotions.
          # If we do not update first, then the item total will be wrong and ItemTotal
          # promotion rules would not be triggered.
          reload_totals
          apply_cart_promotions
        end
        reload_totals if order.completed?
        true
      else
        false
      end
    end

    private

    def after_add_or_remove(line_item, options = {})
      shipment = options[:shipment]
      shipment.present? ? shipment.update_amounts : order.check_shipments_and_restart_checkout
      reload_totals
      apply_cart_promotions(line_item)
      line_item
    end

    def apply_cart_promotions(line_item = nil)
      reload_totals if ::Spree::PromotionHandler::Cart.new(order, line_item).activate
    end
  end
end
