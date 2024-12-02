# frozen_string_literal: true

FactoryBot.define do
  factory :tenant, class: 'Spree::Tenant' do
    sequence(:name) { |n| "Tenant ##{n}" }
  end
end
