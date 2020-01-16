# frozen_string_literal: true

require "active_support/inflector/instance"

module ActiveSupport
  module Inflector
    class << self
      def instance
        @instance ||= Instance.new
      end

      private
        def respond_to_missing?(name, include_private = false)
          instance.respond_to?(name, include_private)
        end

        def method_missing(method, *args, &block)
          instance.public_send(method, *args, &block)
        end
    end
  end
end
