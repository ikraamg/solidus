# frozen_string_literal: true

module SolidusPromotions
  module Conditions
    class Taxon < Condition
      include LineItemApplicableOrderLevelCondition

      include TaxonCondition

      MATCH_POLICIES = %w[any all none].freeze

      validates :preferred_match_policy, inclusion: {in: MATCH_POLICIES}

      preference :match_policy, :string, default: MATCH_POLICIES.first

      def order_eligible?(order, _options = {})
        order_condition.eligibility_errors.clear
        order_condition.order_eligible?(order)
        @eligibility_errors = order_condition.eligibility_errors
        eligibility_errors.empty?
      end

      def line_item_eligible?(line_item, _options = {})
        line_item_condition.eligibility_errors.clear
        result = line_item_condition.line_item_eligible?(line_item)
        @eligibility_errors = line_item_condition.eligibility_errors
        result
      end

      def price_eligible?(price, _options = {})
        price_condition.eligibility_errors.clear
        result = price_condition.price_eligible?(price)
        @eligibility_errors = price_condition.eligibility_errors
        result
      end

      private

      # Memoized to stop rebuilding association scopes per line item, hence the `eligibility_errors.clear` above.
      def order_condition
        @order_condition ||= build_delegate(OrderTaxon, preferred_match_policy)
      end

      def line_item_condition
        @line_item_condition ||= build_delegate(LineItemTaxon, item_match_policy)
      end

      def price_condition
        @price_condition ||= build_delegate(PriceTaxon, item_match_policy)
      end

      def item_match_policy
        preferred_match_policy.in?(%w[any all]) ? "include" : "exclude"
      end

      def build_delegate(condition_class, match_policy)
        condition_class.new(taxons:, preferred_match_policy: match_policy).tap do |condition|
          # Hydrate the instance cache with our @taxon_ids_with_children cache
          condition.taxons_ids_with_children = taxon_ids_with_children
        end
      end
    end
  end
end
