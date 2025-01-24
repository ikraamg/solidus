require 'acts_as_tenant'

module Spree
  module ActsAsTenantAppender
    def self.setup_tenant_aware_classes
      tenant_aware_classes = [
        [Spree.user_class.to_s],
        ["Spree::Address"],
        ["Spree::AdjustmentReason", %i[name code]],
        ["Spree::Adjustment"],
        ["Spree::Asset"],
        ["Spree::Calculator"],
        ["Spree::Carton"],
        ["Spree::CreditCard"],
        ["Spree::CustomerReturn"],
        ["Spree::InventoryUnit"],
        ["Spree::LineItemAction"],
        ["Spree::LineItem"],
        ["Spree::LogEntry"],
        ["Spree::OptionType", %i[name]],
        ["Spree::OptionValue", %i[name]],
        ["Spree::OptionValuesVariant"],
        ["Spree::Order"],
        ["Spree::PaymentCaptureEvent"],
        ["Spree::PaymentMethod"],
        ["Spree::Payment"],
        ["Spree::Preference", %i[key]],
        ["Spree::Price"],
        ["Spree::ProductOptionType"],
        ["Spree::ProductProperty"],
        ["Spree::Product", %i[slug]],
        ["Spree::Property"],
        ["Spree::RefundReason", %i[name]],
        ["Spree::Refund"],
        ["Spree::ReimbursementType", %i[name]],
        ["Spree::Reimbursement"],
        ["Spree::ReturnAuthorization"],
        ["Spree::ReturnItem"],
        ["Spree::ReturnReason"],
        ["Spree::RoleUser"],
        ["Spree::Shipment"],
        ["Spree::ShippingCategory"],
        ["Spree::ShippingMethodCategory"],
        ["Spree::ShippingMethodStockLocation"],
        ["Spree::ShippingMethodZone"],
        ["Spree::ShippingMethod"],
        ["Spree::ShippingRateTax"],
        ["Spree::ShippingRate"],
        ["Spree::StateChange"],
        ["Spree::StockItem"],
        ["Spree::StockLocation", %i[code]],
        ["Spree::StockMovement"],
        ["Spree::StoreCreditCategory"],
        ["Spree::StoreCreditEvent"],
        ["Spree::StoreCreditType"],
        ["Spree::StoreCredit"],
        ["Spree::StorePaymentMethod"],
        ["Spree::Store", %i[code]],
        ["Spree::TaxCategory", %i[name]],
        ["Spree::TaxRate"],
        ["Spree::Taxonomy", %i[name]],
        ["Spree::Taxon"],
        ["Spree::UnitCancel"],
        ["Spree::UserAddress"],
        ["Spree::UserStockLocation"],
        ["Spree::VariantPropertyRuleCondition"],
        ["Spree::VariantPropertyRuleValue"],
        ["Spree::VariantPropertyRule"],
        ["Spree::Variant", %i[sku]],
        ["Spree::ZoneMember"],
        ["Spree::Zone", %i[name]],
        ["Spree::WalletPaymentSource"],
        ["Spree::TaxRateTaxCategory"],
        ["Spree::StoreShippingMethod"],
        ["Spree::StoreCreditReason", %i[name]]
      ]

      tenant_aware_classes.each do |klass, validator_attributes|
        Module.new do
          @validator_attributes = validator_attributes
          define_singleton_method(:prepended) do |base|
            base.include ActsAsTenantModelExtensions
            base.custom_acts_as_tenant :tenant

            @validator_attributes&.each do |attribute|
              validator = base._validators[attribute].find { _1.kind == :uniqueness }
              raise "No uniqueness validator found for #{attribute} on #{base}" unless validator

              new_options = validator.options.dup
              new_options[:scope] = Array(new_options[:scope]).push(:tenant_id)

              base._validators[attribute].reject! { _1.kind == :uniqueness }
              base._validate_callbacks.each do |callback|
                next unless callback.filter.try(:attributes)&.include?(attribute) &&
                            callback.filter.kind == :uniqueness

                callback.filter.attributes.delete(attribute)
              end
              base.validates_uniqueness_of attribute, **new_options
            end
          end

          klass.constantize.prepend(self) if defined?(klass)
        end
      end
    end
  end
end
