# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderContents, type: :model do
  let!(:store) { create :store }
  let(:order) { create(:order) }
  let(:variant) { create(:variant) }
  let!(:stock_location) { variant.stock_locations.first }
  let(:stock_location_2) { create(:stock_location) }

  subject(:order_contents) { described_class.new(order) }

  context "#add" do
    context "without an active promotion" do
      it "recalculates the order only once" do
        allow(order).to receive(:recalculate).and_call_original
        order_contents.add(variant, 1)
        expect(order).to have_received(:recalculate).once
      end
    end

    context "running promotions" do
      let(:promotion) { create(:promotion, apply_automatically: true) }
      let(:calculator) { Spree::Calculator::FlatRate.new(preferred_amount: 10) }

      shared_context "discount changes order total" do
        before { subject.add(variant, 1) }
        it { expect(subject.order.total).not_to eq variant.price }
      end

      context "one active order promotion" do
        let!(:action) { Spree::Promotion::Actions::CreateAdjustment.create(promotion:, calculator:) }

        it "creates valid discount on order" do
          subject.add(variant, 1)
          expect(subject.order.adjustments.to_a.sum(&:amount)).not_to eq 0
        end

        include_context "discount changes order total"
      end

      context "one active line item promotion" do
        let!(:action) { Spree::Promotion::Actions::CreateItemAdjustments.create(promotion:, calculator:) }

        it "creates valid discount on order" do
          subject.add(variant, 1)
          expect(subject.order.line_item_adjustments.to_a.sum(&:amount)).not_to eq 0
        end

        include_context "discount changes order total"
      end
    end
  end

  context "update cart" do
    let!(:shirt) { subject.add variant, 1 }

    let(:params) do
      {line_items_attributes: {
        "0" => {id: shirt.id, quantity: 3}
      }}
    end

    it "changes item quantity" do
      subject.update_cart params
      expect(shirt.reload.quantity).to eq 3
    end

    it "updates order totals" do
      expect {
        subject.update_cart params
      }.to change { subject.order.total }
    end

    context "with an automatic ItemTotal promotion the update makes eligible" do
      let!(:promotion) { create(:promotion, apply_automatically: true) }
      let!(:action) do
        Spree::Promotion::Actions::CreateAdjustment.create(
          promotion:, calculator: Spree::Calculator::FlatRate.new(preferred_amount: 5)
        )
      end
      let!(:rule) do
        Spree::Promotion::Rules::ItemTotal.create(
          preferred_operator: "gt", preferred_amount: variant.price * 2, promotion:
        )
      end

      it "does not apply while the item total is below the threshold" do
        expect(order.adjustments).to be_empty
      end

      it "applies once the raised quantity crosses the threshold" do
        order_contents.update_cart(params)
        expect(order.adjustments.reload.map(&:source)).to include(action)
      end
    end

    context "submits item quantity 0" do
      let(:params) do
        {line_items_attributes: {
          "0" => {id: shirt.id, quantity: 0}
        }}
      end

      it "removes item from order" do
        expect {
          subject.update_cart params
        }.to change { subject.order.line_items.count }
      end
    end

    it "ensures updated shipments" do
      expect(subject.order).to receive(:check_shipments_and_restart_checkout)
      subject.update_cart params
    end
  end

  describe "skipping the redundant recalculation when no promotion changes" do
    let(:order) { create(:order_with_line_items, line_items_count: 1, state: "delivery") }
    let(:recalculate) { -> { order.recalculate } }
    let(:persisted_totals) do
      -> {
        order.reload.attributes.slice(
          "item_total", "adjustment_total", "included_tax_total", "additional_tax_total",
          "promo_total", "shipment_total", "payment_total", "total", "item_count"
        )
      }
    end

    before { mutate.call }

    shared_examples "leaves the order fully recalculated" do
      it "matches what a fresh recalculation would persist" do
        expect(&recalculate).not_to change(&persisted_totals)
      end
    end

    context "when adding an item" do
      let(:mutate) { -> { order_contents.add(create(:variant), 1) } }

      it_behaves_like "leaves the order fully recalculated"
    end

    context "when updating the cart" do
      let(:mutate) { -> { order_contents.update_cart(line_items_attributes: {"0" => {id: order.line_items.first.id, quantity: 3}}) } }

      it_behaves_like "leaves the order fully recalculated"
    end
  end

  context "completed order" do
    let(:order) do
      Spree::Order.create!(
        state: "complete",
        completed_at: Time.current,
        email: "test@example.com"
      )
    end

    before { order.shipments.create! stock_location_id: variant.stock_location_ids.first }

    it "updates order payment state" do
      expect {
        subject.add variant
      }.to change { order.payment_state }

      expect {
        subject.remove variant
      }.to change { order.payment_state }
    end
  end
end
