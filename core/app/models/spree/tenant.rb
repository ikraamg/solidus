# frozen_string_literal: true

module Spree
  class Tenant < Spree::Base
    validates :name, presence: true, uniqueness: true
  end
end
